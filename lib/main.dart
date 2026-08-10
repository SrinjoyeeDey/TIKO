import 'package:flutter/material.dart';
import 'screens/onboarding_screen.dart';
import 'services/app_asset_preloader.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      home: const BootStrapWrapper(),
    );
  }
}

/// Lightweight Bootstrap Wrapper to guarantee Frame 1 asset readiness
class BootStrapWrapper extends StatefulWidget {
  const BootStrapWrapper({super.key});

  @override
  State<BootStrapWrapper> createState() => _BootStrapWrapperState();
}

class _BootStrapWrapperState extends State<BootStrapWrapper> {
  bool _isReady = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isReady) {
      AppAssetPreloader.precacheBootAssets(context).then((_) {
        if (mounted) {
          setState(() {
            _isReady = true;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return Container(
        color: const Color(0xFFC5AE79), // Lightweight branded sepia canvas
      );
    }
    return const OnboardingScreen();
  }
}
