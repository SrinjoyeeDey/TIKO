import 'package:flutter/foundation.dart';

/// Central API Configuration for communicating with Node.js backend.
class ApiConfig {
  /// Base API URL.
  /// Automatically uses `10.0.2.2` for Android Emulator, `localhost` for Web & Desktop.
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api';
    } else {
      return 'http://localhost:3000/api';
    }
  }

  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}
