import 'package:flutter/material.dart';

import '../features/home/home_screen.dart';

class SafeRideApp extends StatelessWidget {
  const SafeRideApp({super.key});

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
      home: const HomeScreen(),
    );
  }
}
