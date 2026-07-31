import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'app/safe_ride_app.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set up authentication + API client (shared across the app).
  final authService = AuthService();
  await authService.initialize();
  final apiClient = ApiClient(authService: authService);

  // Firebase is optional - the app still runs (with local notifications) if
  // the Firebase project files (google-services.json) aren't added.
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (_) {
    // Continue without Firebase / push notifications.
  }

  // Always initialize notifications - local warnings work without Firebase.
  await NotificationService().initialize();

  runApp(SafeRideApp(authService: authService, apiClient: apiClient));
}
