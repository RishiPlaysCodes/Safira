import 'package:flutter/material.dart';

import '../features/auth/login_screen.dart';
import '../features/home/home_screen.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

class SafeRideApp extends StatelessWidget {
  const SafeRideApp({
    super.key,
    required this.authService,
    required this.apiClient,
  });

  final AuthService authService;
  final ApiClient apiClient;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SafeRide Guardian',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF146C94),
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F7FB),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        useMaterial3: true,
      ),
      home: AuthGate(authService: authService, apiClient: apiClient),
    );
  }
}

/// Decides whether to show the login screen or the home screen based on
/// authentication state. Rebuilds automatically when auth state changes.
class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.authService,
    required this.apiClient,
  });

  final AuthService authService;
  final ApiClient apiClient;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: authService,
      builder: (context, _) {
        if (authService.isAuthenticated) {
          return HomeScreen(authService: authService, apiClient: apiClient);
        }
        return LoginScreen(authService: authService);
      },
    );
  }
}
