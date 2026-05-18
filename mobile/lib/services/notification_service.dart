import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationService {
  factory NotificationService() => _instance;
  NotificationService._();

  static final NotificationService _instance = NotificationService._();

  String? _deviceToken;
  String _lastBackendUrl = '';
  String _lastUsername = '';
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? get deviceToken => _deviceToken;

  Future<void> initialize() async {
    await FirebaseMessaging.instance.requestPermission();
    _deviceToken = await FirebaseMessaging.instance.getToken();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
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

    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title ?? 'SafeRide Alert',
          notification.body ?? 'You have a new safety alert.',
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
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      // Later phase: open the relevant alert or trip screen.
    });

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      _deviceToken = newToken;
      registerDeviceWithBackend(
        backendUrl: _lastBackendUrl,
        username: _lastUsername,
      );
    });
  }

  Future<void> registerDeviceWithBackend({
    required String backendUrl,
    required String username,
  }) async {
    _lastBackendUrl = backendUrl;
    _lastUsername = username;
    if (_deviceToken == null || backendUrl.isEmpty || username.isEmpty) return;

    final uri = Uri.tryParse('$backendUrl/alerts/api/register-device/');
    if (uri == null) return;

    try {
      await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': username,
              'token': _deviceToken,
              'platform': 'android',
            }),
          )
          .timeout(const Duration(seconds: 3));
    } catch (_) {}
  }
}
