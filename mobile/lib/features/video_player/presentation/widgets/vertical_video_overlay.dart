import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:video_player/video_player.dart';
import 'package:storyverse/core/models/episode_model.dart';
import 'package:storyverse/core/models/story_model.dart';
import 'package:storyverse/core/theme/design_tokens.dart';
import 'package:storyverse/features/video_player/presentation/widgets/vertical_seek_bar.dart';

class VerticalVideoOverlay extends StatelessWidget {
  final StoryModel story;
  final EpisodeModel episode;
  final VideoPlayerController? controller;
  final bool showControls;
  final bool isMuted;
  final bool isFavorite;
  final bool isInLibrary;
  final bool isCompleted;
  final bool hasNextEpisode;
  final VoidCallback onToggleControls;
  final VoidCallback onTogglePlayPause;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleFavorite;
  final VoidCallback onToggleBookmark;
  final VoidCallback onShare;
  final VoidCallback? onBack;
  final VoidCallback? onOpenEpisodeSelector;
  final VoidCallback? onViewStory;
  final VoidCallback? onNextEpisode;
  final VoidCallback? onReplay;
  final ValueChanged<Duration> onSeek;

  const VerticalVideoOverlay({
    super.key,
    required this.story,
    required this.episode,
    required this.controller,
    required this.showControls,
    required this.isMuted,
    required this.isFavorite,
    required this.isInLibrary,
    this.isCompleted = false,
    this.hasNextEpisode = false,
    required this.onToggleControls,
    required this.onTogglePlayPause,
    required this.onToggleMute,
    required this.onToggleFavorite,
    required this.onToggleBookmark,
    required this.onShare,
    this.onBack,
    this.onOpenEpisodeSelector,
    this.onViewStory,
    this.onNextEpisode,
    this.onReplay,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    final isPlaying = controller?.value.isPlaying ?? false;
    final position = controller?.value.position ?? Duration.zero;
    final duration = controller?.value.duration ?? Duration.zero;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Gesture detector for tapping video & double tap to seek
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: onToggleControls,
          onDoubleTapDown: (details) {
            final screenWidth = MediaQuery.of(context).size.width;
            if (controller == null) return;
            if (details.globalPosition.dx < screenWidth / 2) {
              final newPos = position - const Duration(seconds: 10);
              onSeek(newPos < Duration.zero ? Duration.zero : newPos);
            } else {
              final newPos = position + const Duration(seconds: 10);
              onSeek(newPos > duration ? duration : newPos);
            }
          },
          child: Container(color: Colors.transparent),
        ),

        // 2. Gradients for high contrast text readability
        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.7),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.85),
                ],
                stops: const [0.0, 0.22, 0.55, 1.0],
              ),
            ),
          ),
        ),

        // 3. Center Play/Pause Indicator (visible when paused or when showControls is true)
        if (!isPlaying || showControls)
          Center(
            child: GestureDetector(
              onTap: onTogglePlayPause,
              child: AnimatedOpacity(
                opacity: (!isPlaying || showControls) ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

        // 4. Safe Area Top Bar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: AnimatedOpacity(
              opacity: showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: IgnorePointer(
                ignoring: !showControls,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      // Back Button (if provided)
                      if (onBack != null) ...[
                        _buildGlassButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          onTap: onBack!,
                          iconSize: 18,
                        ),
                        const SizedBox(width: 12),
                      ],

                      // Story Badge
                      Expanded(
                        child: Text(
                          story.title,
                          style: DesignTokens.titleStyle.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Mute / Unmute Button
                      _buildGlassButton(
                        icon: isMuted
                            ? Icons.volume_off_rounded
                            : Icons.volume_up_rounded,
                        color: isMuted ? Colors.white70 : Colors.white,
                        onTap: onToggleMute,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // 5. Right Action Rail (Likes, Bookmarks, Share, Episodes / Story Details)
        Positioned(
          right: 14,
          bottom: 120,
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Favorite / Like
                _buildActionItem(
                  icon: isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  label: 'Like',
                  color: isFavorite ? const Color(0xFFFF2D55) : Colors.white,
                  onTap: onToggleFavorite,
                ),
                const SizedBox(height: 18),

                // Bookmark / Library
                _buildActionItem(
                  icon: isInLibrary
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  label: 'Save',
                  color: isInLibrary
                      ? DesignTokens.primaryAccent
                      : Colors.white,
                  onTap: onToggleBookmark,
                ),
                const SizedBox(height: 18),

                // Share
                _buildActionItem(
                  icon: Icons.share_rounded,
                  label: 'Share',
                  color: Colors.white,
                  onTap: onShare,
                ),
                const SizedBox(height: 18),

                // If Watching Screen: Episodes List Sheet
                if (onOpenEpisodeSelector != null) ...[
                  _buildActionItem(
                    icon: Icons.playlist_play_rounded,
                    label: 'Episodes',
                    color: Colors.white,
                    onTap: onOpenEpisodeSelector!,
                  ),
                ],

                // If Shorts: View Full Story
                if (onViewStory != null) ...[
                  _buildActionItem(
                    icon: Icons.auto_stories_rounded,
                    label: 'Story',
                    color: Colors.white,
                    onTap: onViewStory!,
                  ),
                ],
              ],
            ),
          ),
        ),

        // 6. Bottom Story & Episode Information + Seek Bar
        Positioned(
          left: 16,
          right: 76,
          bottom: 24,
          child: SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Story Title
                Text(
                  story.title,
                  style: DesignTokens.titleStyle.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Episode Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: DesignTokens.primaryAccent.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'EP ${episode.episodeNumber}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        episode.title,
                        style: DesignTokens.bodyStyle.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                if (episode.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    episode.description,
                    style: DesignTokens.bodyStyle.copyWith(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 10),

                // Interactive Progress Slider
                VerticalSeekBar(
                  position: position,
                  duration: duration,
                  onSeek: onSeek,
                ),

                const SizedBox(height: 4),

                // Swipe Hint
                Row(
                  children: [
                    const Icon(
                      Icons.keyboard_arrow_up_rounded,
                      color: Colors.white54,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hasNextEpisode
                          ? 'Swipe up for next episode'
                          : 'Swipe up for more',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // 7. End of Episode Overlay
        if (isCompleted)
          _buildCompletionModal(context),
      ],
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.white,
    double iconSize = 20,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Icon(icon, color: color, size: iconSize),
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              shadows: const [
                Shadow(
                  color: Colors.black87,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionModal(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: DesignTokens.primaryAccent.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: DesignTokens.primaryAccent,
                    width: 2,
                  ),
                ),
                child: Icon(
                  hasNextEpisode
                      ? Icons.check_circle_outline_rounded
                      : Icons.military_tech_rounded,
                  color: DesignTokens.primaryAccent,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                hasNextEpisode ? 'Episode Completed' : 'Series Completed!',
                style: DesignTokens.titleStyle.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                hasNextEpisode
                    ? 'Up next: Episode ${episode.episodeNumber + 1}'
                    : 'You have finished watching all episodes of this story.',
                style: DesignTokens.bodyStyle.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (hasNextEpisode && onNextEpisode != null) ...[
                    ElevatedButton.icon(
                      onPressed: onNextEpisode,
                      icon: const Icon(Icons.skip_next_rounded),
                      label: const Text('Next Episode'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignTokens.primaryAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (onReplay != null)
                    OutlinedButton.icon(
                      onPressed: onReplay,
                      icon: const Icon(Icons.replay_rounded),
                      label: const Text('Replay'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white38),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  if (!hasNextEpisode && onBack != null) ...[
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Back to Story'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignTokens.primaryAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ).animate().scale(duration: 300.ms),
        ),
      ),
    );
  }
}
