import 'package:flutter/material.dart';
import 'package:storyverse/core/theme/design_tokens.dart';
import 'package:storyverse/core/models/episode_model.dart';
import 'package:storyverse/features/video_player/presentation/widgets/now_playing_indicator.dart';

class EpisodeTile extends StatelessWidget {
  final EpisodeModel episode;
  final bool isActive;
  final VoidCallback onTap;

  const EpisodeTile({
    super.key,
    required this.episode,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceGlass,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(
          color: isActive
              ? DesignTokens.primaryAccent.withValues(alpha: 0.5)
              : DesignTokens.surfaceGlassBorder,
          width: isActive ? 1.5 : 1.0,
        ),
        boxShadow: isActive ? DesignTokens.glowShadow : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        child: InkWell(
          onTap: isActive ? null : onTap,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Thumbnail
                Container(
                  width: 100,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
                    color: Colors.black26,
                    image: episode.thumbnailUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(episode.thumbnailUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                    child: Center(
                      child: isActive
                          ? const SizedBox.shrink()
                          : const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EPISODE ${episode.episodeNumber}',
                        style: DesignTokens.labelStyle.copyWith(
                          color: isActive
                              ? DesignTokens.primaryAccent
                              : DesignTokens.textMuted,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        episode.title,
                        style: DesignTokens.sectionHeadingStyle.copyWith(
                          fontSize: 15,
                          color: isActive
                              ? DesignTokens.textPrimary
                              : DesignTokens.textPrimary.withValues(alpha: 0.9),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (episode.duration > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          episode.formattedDuration,
                          style: DesignTokens.bodyStyle.copyWith(
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Active indicator
                if (isActive)
                  const Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: NowPlayingIndicator(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
