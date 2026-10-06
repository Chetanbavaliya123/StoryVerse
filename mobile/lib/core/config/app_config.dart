class AppConfig {
  /// The backend URL is configurable via dart-define:
  /// flutter build apk --dart-define=API_URL=https://your-production-backend.com/api
  static String get aiBackendUrl {
    const envUrl = String.fromEnvironment('API_URL');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }
    // Deployed Render backend
    return 'https://storyverse-ai-backend.onrender.com/api';
  }
}
