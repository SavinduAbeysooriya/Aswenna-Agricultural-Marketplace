import 'package:flutter/material.dart';
import 'package:aswenna/theme/app_theme.dart';
import 'package:aswenna/screens/splash_screen.dart';

void main() {
  runApp(const AswennaApp());
}

class AswennaApp extends StatelessWidget {
  const AswennaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aswenna',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
