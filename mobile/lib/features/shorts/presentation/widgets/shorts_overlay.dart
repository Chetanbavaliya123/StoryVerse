import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:storyverse/core/models/story_model.dart';
import 'package:storyverse/core/models/episode_model.dart';
import 'package:storyverse/core/theme/design_tokens.dart';

class ShortsOverlay extends StatefulWidget {
  final StoryModel story;
  final EpisodeModel episode;
  final bool isMuted;
  final bool isFavorite;
  final bool isInLibrary;
  final bool isCompleted;
  final bool showTapFeedback;
  final bool isPlayingFeedback;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleFavorite;
  final VoidCallback onToggleBookmark;
  final VoidCallback onShare;
  final VoidCallback onViewStory;
  final VoidCallback onTapVideo;

  const ShortsOverlay({
    super.key,
    required this.story,
    required this.episode,
    required this.isMuted,
    required this.isFavorite,
    required this.isInLibrary,
    required this.isCompleted,
    required this.showTapFeedback,
    required this.isPlayingFeedback,
    required this.onToggleMute,
    required this.onToggleFavorite,
    required this.onToggleBookmark,
    required this.onShare,
    required this.onViewStory,
    required this.onTapVideo,
  });

  @override
  State<ShortsOverlay> createState() => _ShortsOverlayState();
}

class _ShortsOverlayState extends State<ShortsOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _bounceAnimation = Tween<double>(begin: 0.0, end: -6.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    if (widget.isCompleted) {
      _bounceController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(ShortsOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCompleted && !_bounceController.isAnimating) {
      _bounceController.repeat(reverse: true);
    } else if (!widget.isCompleted && _bounceController.isAnimating) {
      _bounceController.stop();
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Fullscreen tap recognizer for play/pause toggle
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: widget.onTapVideo,
          child: Container(color: Colors.transparent),
        ),

        // 2. Subtle gradient overlay at top and bottom for readability
        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.5),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.8),
                ],
                stops: const [0.0, 0.18, 0.6, 1.0],
              ),
            ),
          ),
        ),

        // 3. Transient Tap Feedback (briefly appears and disappears, never permanent)
        if (widget.showTapFeedback)
          Center(
            child: IgnorePointer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      widget.isPlayingFeedback
                          ? Icons.play_arrow_rounded
                          : Icons.pause_rounded,
                      color: Colors.white,
                      size: 38,
                    ),
                  ),
                ),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.7, 0.7),
                    end: const Offset(1.0, 1.0),
                    duration: 150.ms,
                    curve: Curves.easeOutBack,
                  )
                  .fadeOut(
                    delay: 250.ms,
                    duration: 250.ms,
                  ),
            ),
          ),

        // 4. Top Control Layer: Mute / Unmute Button
        Positioned(
          top: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: GestureDetector(
                    onTap: widget.onToggleMute,
                    child: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Icon(
                        widget.isMuted
                            ? Icons.volume_off_rounded
                            : Icons.volume_up_rounded,
                        color: widget.isMuted ? Colors.white70 : Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // 5. Right Action Rail: Like, Save, Share, Story Info
        Positioned(
          right: 14,
          bottom: 40,
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Favorite / Like
                _buildActionItem(
                  icon: widget.isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  label: 'Like',
                  color: widget.isFavorite
                      ? const Color(0xFFFF2D55)
                      : Colors.white,
                  onTap: widget.onToggleFavorite,
                ),
                const SizedBox(height: 18),

                // Save / Bookmark
                _buildActionItem(
                  icon: widget.isInLibrary
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  label: 'Save',
                  color: widget.isInLibrary
                      ? DesignTokens.primaryAccent
                      : Colors.white,
                  onTap: widget.onToggleBookmark,
                ),
                const SizedBox(height: 18),

                // Share
                _buildActionItem(
                  icon: Icons.share_rounded,
                  label: 'Share',
                  color: Colors.white,
                  onTap: widget.onShare,
                ),
                const SizedBox(height: 18),

                // View Story (Opens full story details)
                _buildActionItem(
                  icon: Icons.auto_stories_rounded,
                  label: 'Story',
                  color: Colors.white,
                  onTap: widget.onViewStory,
                ),
              ],
            ),
          ),
        ),

        // 6. Bottom Story & Episode Information (NO TIMELINE / NO SEEKBAR)
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
                // Genre & Language Chips
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color:
                            DesignTokens.primaryAccent.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.story.genreId.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.story.language.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Story Title
                Text(
                  widget.story.title,
                  style: DesignTokens.titleStyle.copyWith(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Episode Title
                Text(
                  'EP ${widget.episode.episodeNumber} • ${widget.episode.title}',
                  style: DesignTokens.bodyStyle.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                // 7. Subtle Swipe-Up Suggestion when completed
                if (widget.isCompleted) ...[
                  const SizedBox(height: 12),
                  AnimatedBuilder(
                    animation: _bounceAnimation,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(0, _bounceAnimation.value),
                      child: child,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.keyboard_arrow_up_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Swipe up for next short',
                            style: DesignTokens.bodyStyle.copyWith(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
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
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: Icon(icon, color: color, size: 22),
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
}
