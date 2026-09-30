import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class AppConfig {
  /// Automatically detect local testing environment URL
  /// For production, replace this getter with your actual HTTPS URL
  static String get aiBackendUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000/api';
    }
    return 'http://localhost:3000/api'; // iOS / Windows / macOS
  }
}
