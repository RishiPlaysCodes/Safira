import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../detection/accident_detector.dart';
import '../../models/accident_event.dart';
import '../../models/trip_sample.dart';
import '../../repositories/alert_repository.dart';
import '../../repositories/settings_repository.dart';
import '../../repositories/trip_repository.dart';
import '../../vision/vision_pipeline_service.dart';
import '../../services/emergency_service.dart';
import '../../services/location_service.dart';
import '../../services/sensor_service.dart';
import '../../services/notification_service.dart';

class HomeController extends ChangeNotifier {
  HomeController({
    LocationService? locationService,
    SensorService? sensorService,
    SettingsRepository? settingsRepository,
    TripRepository? tripRepository,
    AlertRepository? alertRepository,
    EmergencyService? emergencyService,
    NotificationService? notificationService,
    AccidentDetector? accidentDetector,
    VisionPipelineService? visionPipelineService,
  })  : _locationService = locationService ?? LocationService(),
        _sensorService = sensorService ?? SensorService(),
        _settingsRepository = settingsRepository ?? SettingsRepository(),
        _tripRepository = tripRepository ?? TripRepository(),
        _alertRepository = alertRepository ?? AlertRepository(),
        _emergencyService = emergencyService ?? EmergencyService(),
        _notificationService = notificationService ?? NotificationService(),
        _accidentDetector = accidentDetector ?? AccidentDetector(),
        _visionPipelineService = visionPipelineService ?? VisionPipelineService();

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

  String parentPhone = '';
  String backendUrl = '';
  String username = '';
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

  Future<void> loadSettings() async {
    parentPhone = await _settingsRepository.loadParentPhone();
    backendUrl = await _settingsRepository.loadBackendUrl();
    username = await _settingsRepository.loadUsername();
    destination = await _settingsRepository.loadDestination();
    notifyListeners();
  }

  Future<void> saveSettings({
    required String newParentPhone,
    required String newBackendUrl,
    required String newUsername,
    required String newDestination,
  }) async {
    parentPhone = newParentPhone.trim();
    backendUrl = newBackendUrl.trim();
    username = newUsername.trim();
    destination = newDestination.trim();
    await _settingsRepository.save(
      parentPhone: parentPhone,
      backendUrl: backendUrl,
      username: username,
      destination: destination,
    );
    await _notificationService.registerDeviceWithBackend(
      backendUrl: backendUrl,
      username: username,
    );
    await _tripRepository.syncPending(backendUrl: backendUrl);
    await _alertRepository.syncPending(backendUrl: backendUrl);
    notifyListeners();
  }

  Future<bool> startTracking() async {
    if (!await _locationService.ensurePermissions()) return false;

    tracking = true;
    notifyListeners();

    await _tripRepository.syncPending(backendUrl: backendUrl);
    await _alertRepository.syncPending(backendUrl: backendUrl);

    _positionSubscription = _locationService.positionStream().listen((position) {
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

      _tripRepository.sendSample(
        backendUrl: backendUrl,
        username: username,
        sample: sample,
      );
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
    countdown = 20;
    _accidentDetector.resetTransientSignals();
    notifyListeners();
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
    await _alertRepository.sendEvent(
      backendUrl: backendUrl,
      username: username,
      event: event,
    );
  }


  Future<void> reportHelmetMissing() async {
    await _visionPipelineService.reportHelmet(
      backendUrl: backendUrl,
      username: username,
      latitude: latitude,
      longitude: longitude,
    );
  }

  Future<void> reportRedLightViolation() async {
    await _visionPipelineService.reportRedLight(
      backendUrl: backendUrl,
      username: username,
      latitude: latitude,
      longitude: longitude,
    );
  }

  Future<void> reportHeavyTraffic() async {
    await _visionPipelineService.reportTrafficDensity(
      backendUrl: backendUrl,
      username: username,
      latitude: latitude,
      longitude: longitude,
    );
  }

  Future<void> _launchEmergencyActions() async {
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
