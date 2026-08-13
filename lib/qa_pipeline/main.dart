import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:media_kit/media_kit.dart';

import 'database/child_repository.dart';
import 'database/database_helper.dart';
import 'models/child_profile.dart';
import 'screens/child_profile_screen.dart';
import 'screens/intro_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  // Initialize the local database.
  await DatabaseHelper.instance.database;

  runApp(const QsAnsApp());
}

class QsAnsApp extends StatelessWidget {
  const QsAnsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Learning',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F0C29),
        useMaterial3: true,
        textTheme: GoogleFonts.outfitTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ),
      ),
      home: const _AppEntryPoint(),
    );
  }
}

/// Checks for an existing child profile and routes accordingly.
class _AppEntryPoint extends StatefulWidget {
  const _AppEntryPoint();

  @override
  State<_AppEntryPoint> createState() => _AppEntryPointState();
}

class _AppEntryPointState extends State<_AppEntryPoint> {
  bool _isLoading = true;
  ChildProfile? _existingProfile;

  @override
  void initState() {
    super.initState();
    _checkProfile();
  }

  Future<void> _checkProfile() async {
    final profile = await ChildRepository.getActiveChild();
    if (mounted) {
      setState(() {
        _existingProfile = profile;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0C29),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
        ),
      );
    }

    // If a profile exists, go directly to intro → level map.
    if (_existingProfile != null) {
      return IntroScreen(childId: _existingProfile!.id);
    }

    // Otherwise, show child profile creation.
    return ChildProfileScreen(
      onProfileCreated: (profile) {
        setState(() {
          _existingProfile = profile;
        });
      },
    );
  }
}
