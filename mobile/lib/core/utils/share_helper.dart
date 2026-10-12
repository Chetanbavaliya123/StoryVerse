import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:storyverse/core/theme/design_tokens.dart';

class ShareHelper {
  static void shareStory({
    required BuildContext context,
    required String storyId,
    required String title,
    String? episodeTitle,
  }) {
    final link = 'https://storyverse.app/story/$storyId';
    final textToCopy = episodeTitle != null && episodeTitle.isNotEmpty
        ? 'Watch "$episodeTitle" from "$title" on StoryVerse: $link'
        : 'Watch "$title" on StoryVerse: $link';

    Clipboard.setData(ClipboardData(text: textToCopy));

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1F1F1F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0x33FFFFFF)),
        ),
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: DesignTokens.primaryAccent,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Story link copied to clipboard!',
                style: DesignTokens.bodyStyle.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
