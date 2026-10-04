import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class AppConfig {
  /// The backend URL is configurable via dart-define:
  /// flutter build apk --dart-define=API_URL=https://your-production-backend.com/api
  static String get aiBackendUrl {
    const envUrl = String.fromEnvironment('API_URL');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }
    // Safe fallback for USB debugging.
    // We use adb reverse tcp:3000 tcp:3000 to tunnel the device's localhost to the laptop.
    return 'http://localhost:3000/api';
  }
}
