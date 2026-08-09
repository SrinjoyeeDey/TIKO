import 'package:flutter/material.dart';
import 'screens/onboarding_screen.dart';

void main() {
  runApp(const NimoApp());
}

class NimoApp extends StatelessWidget {
  const NimoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NIMO — Nature Adventure',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Outfit',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50),
        ),
      ),
      home: const OnboardingScreen(),
    );
  }
}
