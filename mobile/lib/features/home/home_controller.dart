import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../detection/accident_detector.dart';
import '../../models/accident_event.dart';
import '../../models/trip_sample.dart';
import '../../repositories/alert_repository.dart';
import '../../repositories/settings_repository.dart';
import '../../repositories/trip_repository.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/emergency_service.dart';
import '../../services/location_service.dart';
import '../../services/notification_service.dart';
import '../../services/sensor_service.dart';
import '../../vision/vision_pipeline_service.dart';

class HomeController extends ChangeNotifier {
  HomeController({
    required AuthService authService,
    required ApiClient apiClient,
    LocationService? locationService,
    SensorService? sensorService,
    SettingsRepository? settingsRepository,
    TripRepository? tripRepository,
    AlertRepository? alertRepository,
    EmergencyService? emergencyService,
    NotificationService? notificationService,
    AccidentDetector? accidentDetector,
    VisionPipelineService? visionPipelineService,
  })  : _authService = authService,
        _locationService = locationService ?? LocationService(),
        _sensorService = sensorService ?? SensorService(),
        _settingsRepository = settingsRepository ?? SettingsRepository(),
        _tripRepository =
            tripRepository ?? TripRepository(apiClient: apiClient),
        _alertRepository =
            alertRepository ?? AlertRepository(apiClient: apiClient),
        _emergencyService = emergencyService ?? EmergencyService(),
        _notificationService = notificationService ?? NotificationService(),
        _accidentDetector = accidentDetector ?? AccidentDetector(),
        _visionPipelineService = visionPipelineService ??
            VisionPipelineService(apiClient: apiClient) {
    // Let the notification service register devices with token auth.
    _notificationService.useApiClient(apiClient);
  }

  final AuthService _authService;
  final LocationService _locationService;
  final SensorService _sensorService;
  final SettingsRepository _settingsRepository;
  final TripRepository _tripRepository;
  final AlertRepository _alertRepository;
  final EmergencyService _emergencyService;
  final NotificationService _notificationService;
  final AccidentDetector _accidentDetector;
  final VisionPipelineService _visionPipelineService;

  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<double>? _impactSubscription;
  Timer? _countdownTimer;

  String get username => _authService.username ?? '';

  String parentPhone = '';
  String backendUrl = '';
  String destination = '';
  bool tracking = false;
  bool accidentSuspicion = false;
  int countdown = 20;
  double speedKmh = 0;
  double latitude = 0;
  double longitude = 0;
  double impactG = 0;
  final double speedLimitKmh = 40;
  final List<TripSample> routeSamples = [];

  // Overspeed tracking (for sustained-overspeed guardian warning).
  bool overspeedWarningActive = false;
  DateTime? _overspeedStartedAt;
  DateTime? _lastOverspeedNotifiedAt;

  Future<void> loadSettings() async {
    parentPhone = await _settingsRepository.loadParentPhone();
    backendUrl = await _settingsRepository.loadBackendUrl();
    destination = await _settingsRepository.loadDestination();
    notifyListeners();
  }

  Future<void> saveSettings({
    required String newParentPhone,
    required String newBackendUrl,
    required String newDestination,
  }) async {
    parentPhone = newParentPhone.trim();
    backendUrl = newBackendUrl.trim();
    destination = newDestination.trim();
    await _settingsRepository.save(
      parentPhone: parentPhone,
      backendUrl: backendUrl,
      destination: destination,
    );
    await _notificationService.registerDeviceWithBackend(backendUrl: backendUrl);
    await _tripRepository.syncPending(backendUrl: backendUrl);
    await _alertRepository.syncPending(backendUrl: backendUrl);
    notifyListeners();
  }

  Future<void> logout() async {
    await stopTracking();
    await _authService.logout(backendUrl: backendUrl);
  }

  Future<bool> startTracking() async {
    if (!await _locationService.ensurePermissions()) return false;

    tracking = true;
    notifyListeners();

    await _tripRepository.syncPending(backendUrl: backendUrl);
    await _alertRepository.syncPending(backendUrl: backendUrl);

    _positionSubscription =
        _locationService.positionStream().listen((position) {
      final sample = TripSample(
        latitude: position.latitude,
        longitude: position.longitude,
        speedKmh: (position.speed < 0 ? 0 : position.speed) * 3.6,
        recordedAt: DateTime.now(),
        destination: destination,
      );

      speedKmh = sample.speedKmh;
      latitude = sample.latitude;
      longitude = sample.longitude;
      routeSamples.add(sample);
      if (routeSamples.length > 500) {
        routeSamples.removeAt(0);
      }

      _checkOverspeed(sample);

      _tripRepository.sendSample(backendUrl: backendUrl, sample: sample);
      if (_accidentDetector.addTripSample(sample)) {
        _startAccidentCountdown(sample);
      }
      notifyListeners();
    });

    _impactSubscription = _sensorService.impactStream().listen((gForce) {
      impactG = gForce;
      _accidentDetector.addImpact(gForce, DateTime.now());
      notifyListeners();
    });

    return true;
  }

  Future<void> stopTracking() async {
    await _positionSubscription?.cancel();
    await _impactSubscription?.cancel();
    _countdownTimer?.cancel();
    tracking = false;
    accidentSuspicion = false;
    overspeedWarningActive = false;
    _overspeedStartedAt = null;
    countdown = 20;
    _accidentDetector.resetTransientSignals();
    notifyListeners();
  }

  /// Detects sustained overspeed and warns the rider + notifies the guardian.
  /// Debounced so the guardian is not spammed (max one alert per 3 minutes).
  void _checkOverspeed(TripSample sample) {
    final now = sample.recordedAt;
    final isOver = sample.speedKmh > speedLimitKmh;

    if (!isOver) {
      overspeedWarningActive = false;
      _overspeedStartedAt = null;
      return;
    }

    overspeedWarningActive = true;
    _overspeedStartedAt ??= now;

    final sustained = now.difference(_overspeedStartedAt!).inSeconds >= 10;
    final severe = sample.speedKmh > speedLimitKmh * 1.25;

    final canNotify = _lastOverspeedNotifiedAt == null ||
        now.difference(_lastOverspeedNotifiedAt!).inMinutes >= 3;

    if ((sustained || severe) && canNotify) {
      _lastOverspeedNotifiedAt = now;
      _notificationService.showLocalWarning(
        title: 'Overspeed warning',
        body:
            'You are riding at ${sample.speedKmh.toStringAsFixed(0)} km/h (limit ${speedLimitKmh.toStringAsFixed(0)}). Slow down.',
      );
      // Record an overspeed alert on the backend so guardians see it in history.
      _alertRepository.sendEvent(
        backendUrl: backendUrl,
        event: AccidentEvent(
          status: 'overspeed',
          impactG: 0,
          sample: sample,
        ),
      );
    }
  }

  void markSafe() {
    _countdownTimer?.cancel();
    accidentSuspicion = false;
    countdown = 20;
    _accidentDetector.resetTransientSignals();
    notifyListeners();
  }

  Future<void> confirmAccidentNow() async {
    _countdownTimer?.cancel();
    accidentSuspicion = false;
    notifyListeners();
    await _sendAlert('confirmed_no_response');
    await _launchEmergencyActions();
    _accidentDetector.resetTransientSignals();
  }

  Future<void> manualSos() async {
    await _sendAlert('manual_sos');
    await _launchEmergencyActions();
  }

  void _startAccidentCountdown(TripSample sample) {
    accidentSuspicion = true;
    countdown = 20;
    notifyListeners();
    _sendAlert('suspicious');
    _notificationService.showLocalWarning(
      title: 'Possible accident detected',
      body: 'Tap the app. Guardian will be alerted if you do not respond.',
    );

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown <= 1) {
        timer.cancel();
        confirmAccidentNow();
      } else {
        countdown--;
        notifyListeners();
      }
    });
  }

  Future<void> _sendAlert(String status) async {
    final sample = TripSample(
      latitude: latitude,
      longitude: longitude,
      speedKmh: speedKmh,
      recordedAt: DateTime.now(),
      destination: destination,
    );
    final event = AccidentEvent(
      status: status,
      impactG: impactG,
      sample: sample,
    );
    await _alertRepository.sendEvent(backendUrl: backendUrl, event: event);
  }

  Future<void> reportHelmetMissing() async {
    await _visionPipelineService.reportHelmet(
      backendUrl: backendUrl,
      latitude: latitude,
      longitude: longitude,
    );
  }

  Future<void> reportRedLightViolation() async {
    await _visionPipelineService.reportRedLight(
      backendUrl: backendUrl,
      latitude: latitude,
      longitude: longitude,
    );
  }

  Future<void> reportHeavyTraffic() async {
    await _visionPipelineService.reportTrafficDensity(
      backendUrl: backendUrl,
      latitude: latitude,
      longitude: longitude,
    );
  }

  Future<void> _launchEmergencyActions() async {
    if (parentPhone.isEmpty) return;
    final link = 'https://maps.google.com/?q=$latitude,$longitude';
    await _emergencyService.openSms(phone: parentPhone, mapsLink: link);
    await _emergencyService.openCall(phone: parentPhone);
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _impactSubscription?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }
}
