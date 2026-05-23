import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../features/home/home_screen.dart';
import 'theme.dart';

class SafeRideApp extends StatelessWidget {
  const SafeRideApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF0A0E21),
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SafeRide Guardian',
      theme: SafeRideTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
