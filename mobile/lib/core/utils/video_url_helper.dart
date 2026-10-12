import 'package:flutter/foundation.dart';

class VideoUrlHelper {
  /// Normalizes video URLs from various sources (Direct MP4, Google Drive, etc.)
  /// to ensure direct streaming playback in video_player.
  static String normalize(String rawUrl) {
    if (rawUrl.trim().isEmpty) return '';

    String url = rawUrl.trim();

    // 1. Google Drive URLs
    if (url.contains('drive.google.com')) {
      final driveMatch = RegExp(r'(?:file\/d\/|id=)([a-zA-Z0-9_-]+)').firstMatch(url);
      if (driveMatch != null && driveMatch.group(1) != null) {
        final fileId = driveMatch.group(1);
        url = 'https://drive.google.com/uc?export=download&confirm=t&id=$fileId';

        if (kIsWeb) {
          url = 'https://corsproxy.io/?${Uri.encodeComponent(url)}';
        }
      }
    }

    // 2. Map defunct Google sample videos (gtv-videos-bucket returns 403) to high-speed reliable CDN streams
    if (url.contains('commondatastorage.googleapis.com') ||
        url.contains('gtv-videos-bucket')) {
      if (url.contains('BigBuckBunny')) {
        url = 'https://raw.githubusercontent.com/mediaelement/mediaelement-files/master/big_buck_bunny.mp4';
      } else if (url.contains('ElephantsDream')) {
        url = 'https://vjs.zencdn.net/v/oceans.mp4';
      } else if (url.contains('ForBiggerBlazes')) {
        url = 'https://cdn.plyr.io/static/demo/View_From_A_Blue_Moon_Trailer-576p.mp4';
      } else {
        url = 'https://vjs.zencdn.net/v/oceans.mp4';
      }
    }

    return url;
  }

  /// Checks if URL is a YouTube link (which cannot be played by native video_player directly)
  static bool isYouTube(String url) {
    return url.contains('youtube.com') || url.contains('youtu.be');
  }
}
