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
    // For release builds, we must use API_URL. If missing, return empty.
    if (kReleaseMode) {
      return '';
    }

    // Safe fallback for local development if no --dart-define is provided
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000/api';
    }
    return 'http://localhost:3000/api';
  }
}
