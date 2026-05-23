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
import '../../services/activity_recognition_service.dart';
import '../../services/emergency_service.dart';
import '../../services/live_location_service.dart';
import '../../services/location_service.dart';
import '../../services/sensor_service.dart';
import '../../services/notification_service.dart';
import '../../services/traffic_service.dart';

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
    ActivityRecognitionService? activityRecognitionService,
    LiveLocationService? liveLocationService,
    TrafficService? trafficService,
  })  : _locationService = locationService ?? LocationService(),
        _sensorService = sensorService ?? SensorService(),
        _settingsRepository = settingsRepository ?? SettingsRepository(),
        _tripRepository = tripRepository ?? TripRepository(),
        _alertRepository = alertRepository ?? AlertRepository(),
        _emergencyService = emergencyService ?? EmergencyService(),
        _notificationService = notificationService ?? NotificationService(),
        _accidentDetector = accidentDetector ?? AccidentDetector(),
        _visionPipelineService = visionPipelineService ?? VisionPipelineService(),
        _activityService = activityRecognitionService ?? ActivityRecognitionService(),
        _liveLocationService = liveLocationService ?? LiveLocationService(),
        _trafficService = trafficService ?? TrafficService();

  final LocationService _locationService;
  final SensorService _sensorService;
  final SettingsRepository _settingsRepository;
  final TripRepository _tripRepository;
  final AlertRepository _alertRepository;
  final EmergencyService _emergencyService;
  final NotificationService _notificationService;
  final AccidentDetector _accidentDetector;
  final VisionPipelineService _visionPipelineService;
  final ActivityRecognitionService _activityService;
  final LiveLocationService _liveLocationService;
  final TrafficService _trafficService;

  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<double>? _impactSubscription;
  StreamSubscription<ActivityState>? _activitySubscription;
  Timer? _countdownTimer;
  Timer? _trafficCheckTimer;
  Timer? _nearbyPlacesTimer;

  // Settings
  String parentPhone = '';
  String backendUrl = '';
  String username = '';
  String destination = '';

  // Tracking state
  bool tracking = false;
  bool autoOnEnabled = true;
  bool accidentSuspicion = false;
  bool liveLocationSharing = false;
  int countdown = 20;

  // Sensor data
  double speedKmh = 0;
  double latitude = 0;
  double longitude = 0;
  double impactG = 0;
  double speedLimitKmh = 40;

  // Traffic
  TrafficLevel trafficLevel = TrafficLevel.unknown;
  String trafficReason = '';
  int congestionPercent = 0;
  List<NearbyPlace> nearbyPlaces = [];

  // Stats
  int totalTripsToday = 0;
  int overspeedEvents = 0;
  double maxSpeedToday = 0;
  double totalDistanceKm = 0;

  // Live location
  String liveTrackingLink = '';

  final List<TripSample> routeSamples = [];

  Future<void> loadSettings() async {
    parentPhone = await _settingsRepository.loadParentPhone();
    backendUrl = await _settingsRepository.loadBackendUrl();
    username = await _settingsRepository.loadUsername();
    destination = await _settingsRepository.loadDestination();
    autoOnEnabled = await _settingsRepository.loadAutoOn();
    notifyListeners();

    // Start auto-on monitoring if enabled
    if (autoOnEnabled) {
      _startAutoOnMonitoring();
    }
  }

  Future<void> saveSettings({
    required String newParentPhone,
    required String newBackendUrl,
    required String newUsername,
    required String newDestination,
    bool? newAutoOnEnabled,
  }) async {
    parentPhone = newParentPhone.trim();
    backendUrl = newBackendUrl.trim();
    username = newUsername.trim();
    destination = newDestination.trim();
    if (newAutoOnEnabled != null) {
      autoOnEnabled = newAutoOnEnabled;
    }
    await _settingsRepository.save(
      parentPhone: parentPhone,
      backendUrl: backendUrl,
      username: username,
      destination: destination,
      autoOn: autoOnEnabled,
    );
    await _notificationService.registerDeviceWithBackend(
      backendUrl: backendUrl,
      username: username,
    );
    await _tripRepository.syncPending(backendUrl: backendUrl);
    await _alertRepository.syncPending(backendUrl: backendUrl);
    notifyListeners();
  }

  // ============ AUTO-ON FEATURE ============

  void _startAutoOnMonitoring() {
    _activitySubscription?.cancel();
    _activityService.startMonitoring();
    _activitySubscription = _activityService.activityStream.listen((state) {
      if (state == ActivityState.driving && !tracking) {
        debugPrint('[AutoOn] Driving detected — auto-starting tracking');
        startTracking();
      } else if (state == ActivityState.stationary && tracking) {
        debugPrint('[AutoOn] Stationary detected — auto-stopping tracking');
        stopTracking();
      }
    });
  }

  void toggleAutoOn(bool enabled) {
    autoOnEnabled = enabled;
    if (enabled) {
      _startAutoOnMonitoring();
    } else {
      _activitySubscription?.cancel();
      _activityService.stopMonitoring();
    }
    _settingsRepository.save(
      parentPhone: parentPhone,
      backendUrl: backendUrl,
      username: username,
      destination: destination,
      autoOn: enabled,
    );
    notifyListeners();
  }

  // ============ TRACKING ============

  Future<bool> startTracking() async {
    if (!await _locationService.ensurePermissions()) return false;

    tracking = true;
    notifyListeners();

    await _tripRepository.syncPending(backendUrl: backendUrl);
    await _alertRepository.syncPending(backendUrl: backendUrl);

    _positionSubscription = _locationService.positionStream().listen(_onPositionUpdate);

    _impactSubscription = _sensorService.impactStream().listen((gForce) {
      impactG = gForce;
      _accidentDetector.addImpact(gForce, DateTime.now());
      notifyListeners();
    });

    // Start traffic monitoring
    _trafficCheckTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkTraffic();
    });

    // Check nearby places every 30 seconds
    _nearbyPlacesTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkNearbyPlaces();
    });

    return true;
  }

  void _onPositionUpdate(Position position) {
    final sample = TripSample(
      latitude: position.latitude,
      longitude: position.longitude,
      speedKmh: (position.speed < 0 ? 0 : position.speed) * 3.6,
      recordedAt: DateTime.now(),
      destination: destination,
    );

    // Update distance
    if (routeSamples.isNotEmpty) {
      final lastSample = routeSamples.last;
      final dist = Geolocator.distanceBetween(
        lastSample.latitude, lastSample.longitude,
        sample.latitude, sample.longitude,
      );
      totalDistanceKm += dist / 1000;
    }

    speedKmh = sample.speedKmh;
    latitude = sample.latitude;
    longitude = sample.longitude;

    // Track max speed
    if (speedKmh > maxSpeedToday) {
      maxSpeedToday = speedKmh;
    }

    // Overspeed detection
    if (speedKmh > speedLimitKmh) {
      overspeedEvents++;
    }

    routeSamples.add(sample);
    if (routeSamples.length > 1000) {
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
  }

  Future<void> stopTracking() async {
    await _positionSubscription?.cancel();
    await _impactSubscription?.cancel();
    _countdownTimer?.cancel();
    _trafficCheckTimer?.cancel();
    _nearbyPlacesTimer?.cancel();
    tracking = false;
    accidentSuspicion = false;
    countdown = 20;
    _accidentDetector.resetTransientSignals();
    totalTripsToday++;
    notifyListeners();
  }

  // ============ LIVE LOCATION SHARING ============

  Future<void> startLiveLocationSharing() async {
    final link = await _liveLocationService.startSharing(
      backendUrl: backendUrl,
      username: username,
      guardianPhone: parentPhone,
    );
    liveTrackingLink = link;
    liveLocationSharing = true;
    notifyListeners();
  }

  Future<void> stopLiveLocationSharing() async {
    await _liveLocationService.stopSharing(
      backendUrl: backendUrl,
      username: username,
    );
    liveLocationSharing = false;
    notifyListeners();
  }

  Future<void> shareLiveLocationWithGuardian() async {
    if (!liveLocationSharing) {
      await startLiveLocationSharing();
    }
    final message = _liveLocationService.getEmergencyMessage(riderName: username);
    await _emergencyService.openSms(phone: parentPhone, mapsLink: liveTrackingLink);
  }

  // ============ TRAFFIC DETECTION ============

  void _checkTraffic() {
    if (speedKmh <= 0) return;

    final assessment = _trafficService.assessTraffic(
      currentSpeedKmh: speedKmh,
      expectedSpeedKmh: speedLimitKmh,
      latitude: latitude,
      longitude: longitude,
    );

    trafficLevel = assessment.level;
    trafficReason = assessment.reason;
    congestionPercent = assessment.congestionPercent;
    notifyListeners();
  }

  Future<void> _checkNearbyPlaces() async {
    if (latitude == 0 && longitude == 0) return;

    nearbyPlaces = await _trafficService.getNearbyPlaces(
      latitude: latitude,
      longitude: longitude,
    );

    // Adjust speed limit based on zone
    final recommendedLimit = _trafficService.getRecommendedSpeedLimit(nearbyPlaces);
    if (recommendedLimit != speedLimitKmh) {
      speedLimitKmh = recommendedLimit;
      debugPrint('[Zones] Speed limit adjusted to $speedLimitKmh km/h');
    }

    notifyListeners();
  }

  // ============ ACCIDENT HANDLING ============

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

    // Start live location sharing immediately
    await startLiveLocationSharing();

    await _sendAlert('confirmed_no_response');
    await _launchEmergencyActions();
    _accidentDetector.resetTransientSignals();
  }

  Future<void> manualSos() async {
    // Start live location sharing immediately
    await startLiveLocationSharing();

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

  // ============ VISION REPORTS ============

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

  // ============ EMERGENCY ============

  Future<void> _launchEmergencyActions() async {
    final liveLink = liveLocationSharing
        ? liveTrackingLink
        : 'https://maps.google.com/?q=$latitude,$longitude';

    final message = 'SafeRide Guardian EMERGENCY!\n'
        'Rider: $username\n'
        'Possible accident detected.\n'
        'Live Location: $liveLink\n'
        'Speed: ${speedKmh.toStringAsFixed(1)} km/h\n'
        'Impact: ${impactG.toStringAsFixed(2)}g\n'
        'Time: ${DateTime.now().toString().substring(0, 19)}';

    await _emergencyService.openSmsWithMessage(
      phone: parentPhone,
      message: message,
    );
    await _emergencyService.openCall(phone: parentPhone);
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _impactSubscription?.cancel();
    _activitySubscription?.cancel();
    _countdownTimer?.cancel();
    _trafficCheckTimer?.cancel();
    _nearbyPlacesTimer?.cancel();
    _activityService.dispose();
    _liveLocationService.dispose();
    super.dispose();
  }
}
