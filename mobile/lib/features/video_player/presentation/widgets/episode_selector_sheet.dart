import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storyverse/core/models/episode_model.dart';
import 'package:storyverse/core/models/story_model.dart';
import 'package:storyverse/core/theme/design_tokens.dart';
import 'package:storyverse/core/widgets/network_image_with_fallback.dart';

class EpisodeSelectorSheet extends ConsumerWidget {
  final StoryModel story;
  final List<EpisodeModel> episodes;
  final int currentIndex;
  final ValueChanged<int> onSelectEpisode;

  const EpisodeSelectorSheet({
    super.key,
    required this.story,
    required this.episodes,
    required this.currentIndex,
    required this.onSelectEpisode,
  });

  static Future<void> show({
    required BuildContext context,
    required StoryModel story,
    required List<EpisodeModel> episodes,
    required int currentIndex,
    required ValueChanged<int> onSelectEpisode,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => EpisodeSelectorSheet(
        story: story,
        episodes: episodes,
        currentIndex: currentIndex,
        onSelectEpisode: onSelectEpisode,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.65,
          decoration: BoxDecoration(
            color: const Color(0xFF141416).withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            story.title,
                            style: DesignTokens.titleStyle.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'All Episodes (${episodes.length})',
                            style: DesignTokens.bodyStyle.copyWith(
                              fontSize: 12,
                              color: DesignTokens.primaryAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(color: Color(0x1AFFFFFF), height: 1),

              // Episodes List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: episodes.length,
                  itemBuilder: (context, index) {
                    final ep = episodes[index];
                    final isCurrent = index == currentIndex;

                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                        if (!isCurrent) {
                          onSelectEpisode(index);
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? DesignTokens.primaryAccent.withValues(alpha: 0.15)
                              : Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isCurrent
                                ? DesignTokens.primaryAccent.withValues(alpha: 0.6)
                                : Colors.white.withValues(alpha: 0.06),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Thumbnail
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: NetworkImageWithFallback(
                                    imageUrl: ep.thumbnailUrl,
                                    width: 80,
                                    height: 52,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                if (isCurrent)
                                  Container(
                                    width: 80,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.equalizer_rounded,
                                      color: DesignTokens.primaryAccent,
                                      size: 24,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 14),

                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'EPISODE ${ep.episodeNumber}',
                                        style: DesignTokens.labelStyle.copyWith(
                                          fontSize: 10,
                                          color: isCurrent
                                              ? DesignTokens.primaryAccent
                                              : Colors.white70,
                                        ),
                                      ),
                                      if (isCurrent) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: DesignTokens.primaryAccent,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'PLAYING',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    ep.title,
                                    style: DesignTokens.bodyStyle.copyWith(
                                      color: Colors.white,
                                      fontWeight: isCurrent
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    ep.formattedDuration,
                                    style: DesignTokens.bodyStyle.copyWith(
                                      fontSize: 11,
                                      color: Colors.white38,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Icon(
                              isCurrent
                                  ? Icons.play_arrow_rounded
                                  : Icons.chevron_right_rounded,
                              color: isCurrent
                                  ? DesignTokens.primaryAccent
                                  : Colors.white38,
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
