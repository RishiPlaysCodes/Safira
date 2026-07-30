import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'api_client.dart';

/// Handles push notifications (FCM) and on-device local notifications.
/// Device registration uses token-based authentication via [ApiClient].
class NotificationService {
  factory NotificationService() => _instance;
  NotificationService._();

  static final NotificationService _instance = NotificationService._();

  String? _deviceToken;
  String _lastBackendUrl = '';
  ApiClient? _apiClient;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? get deviceToken => _deviceToken;

  /// Attach the authenticated API client so device registration can send
  /// the auth token. Called by the app once the user is logged in.
  void useApiClient(ApiClient client) {
    _apiClient = client;
  }

  /// Initialize notifications. Local notifications are set up first and always
  /// work (no Firebase required). Firebase Cloud Messaging is optional and only
  /// activates when a Firebase project (google-services.json) is configured.
  Future<void> initialize() async {
    await _initLocalNotifications();
    await _initFirebaseMessaging();
  }

  Future<void> _initLocalNotifications() async {
    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initializationSettings =
          InitializationSettings(android: androidSettings);
      await _localNotifications.initialize(initializationSettings);

      const channel = AndroidNotificationChannel(
        'saferide_alerts',
        'SafeRide Alerts',
        description: 'Emergency and safety alerts',
        importance: Importance.high,
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    } catch (_) {
      // Local notifications unavailable (e.g. running in a test harness).
    }
  }

  Future<void> _initFirebaseMessaging() async {
    try {
      await FirebaseMessaging.instance.requestPermission();
      _deviceToken = await FirebaseMessaging.instance.getToken();

      FirebaseMessaging.onMessage.listen((message) {
        final notification = message.notification;
        if (notification != null) {
          showLocalWarning(
            title: notification.title ?? 'SafeRide Alert',
            body: notification.body ?? 'You have a new safety alert.',
          );
        }
      });

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _deviceToken = newToken;
        registerDeviceWithBackend(backendUrl: _lastBackendUrl);
      });
    } catch (_) {
      // Firebase not configured - app runs with local notifications only.
    }
  }

  /// Show a high-priority local notification on the device.
  Future<void> showLocalWarning({
    required String title,
    required String body,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    await _localNotifications.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'saferide_alerts',
          'SafeRide Alerts',
          channelDescription: 'Emergency and safety alerts',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  /// Register this device's FCM token with the backend using token auth.
  Future<void> registerDeviceWithBackend({required String backendUrl}) async {
    _lastBackendUrl = backendUrl;
    final client = _apiClient;
    if (_deviceToken == null || backendUrl.isEmpty || client == null) return;
    if (!client.authService.isAuthenticated) return;

    await client.post(
      backendUrl,
      '/alerts/api/register-device/',
      {'token': _deviceToken, 'platform': 'android'},
    );
  }
}
