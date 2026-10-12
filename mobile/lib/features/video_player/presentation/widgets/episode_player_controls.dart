import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:video_player/video_player.dart';
import 'package:storyverse/core/models/episode_model.dart';
import 'package:storyverse/core/models/story_model.dart';
import 'package:storyverse/core/theme/design_tokens.dart';
import 'package:storyverse/features/video_player/presentation/widgets/vertical_seek_bar.dart';

class EpisodePlayerControls extends StatelessWidget {
  final StoryModel story;
  final EpisodeModel episode;
  final VideoPlayerController? controller;
  final bool showControls;
  final bool isMuted;
  final bool isInitialized;
  final bool showTapFeedback;
  final bool isPlayingFeedback;
  final VoidCallback onTapVideo;
  final VoidCallback onToggleMute;
  final VoidCallback onBack;
  final ValueChanged<Duration> onSeek;

  const EpisodePlayerControls({
    super.key,
    required this.story,
    required this.episode,
    required this.controller,
    required this.showControls,
    required this.isMuted,
    this.isInitialized = true,
    this.showTapFeedback = false,
    this.isPlayingFeedback = false,
    required this.onTapVideo,
    required this.onToggleMute,
    required this.onBack,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveInitialized = isInitialized && (controller == null || controller!.value.isInitialized);
    final position = controller?.value.position ?? Duration.zero;
    final duration = controller?.value.duration ?? Duration.zero;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Screen Tap Detector: taps toggle play/pause & brief feedback
        GestureDetector(
          key: const Key('episode_screen_tap_detector'),
          behavior: HitTestBehavior.translucent,
          onTap: onTapVideo,
          onDoubleTapDown: (details) {
            if (controller == null) return;
            final screenWidth = MediaQuery.of(context).size.width;
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

        // 2. Gradients overlay (only visible when controls are visible)
        AnimatedOpacity(
          opacity: (showControls && effectiveInitialized) ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 250),
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.75),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.85),
                  ],
                  stops: const [0.0, 0.22, 0.6, 1.0],
                ),
              ),
            ),
          ),
        ),

        // 3. Transient Tap Feedback (briefly appears on tap, then fades to invisible, same as Shorts!)
        if (showTapFeedback)
          Center(
            child: IgnorePointer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      isPlayingFeedback
                          ? Icons.play_arrow_rounded
                          : Icons.pause_rounded,
                      color: Colors.white,
                      size: 40,
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

        // 4. Top Controls: BACK (left) and MUTE (right)
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      // Back Button
                      ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: GestureDetector(
                            onTap: onBack,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.4),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Episode Header Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              story.title,
                              style: DesignTokens.titleStyle.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Episode ${episode.episodeNumber}',
                              style: DesignTokens.bodyStyle.copyWith(
                                fontSize: 11,
                                color: DesignTokens.primaryAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Mute / Unmute Button
                      ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: GestureDetector(
                            onTap: onToggleMute,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.4),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Icon(
                                isMuted
                                    ? Icons.volume_off_rounded
                                    : Icons.volume_up_rounded,
                                color: isMuted ? Colors.white70 : Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // 5. Bottom Controls: PLAYBACK TIMELINE + Episode Title (Interactive)
        Positioned(
          left: 16,
          right: 16,
          bottom: 24,
          child: SafeArea(
            top: false,
            child: AnimatedOpacity(
              opacity: showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: IgnorePointer(
                ignoring: !showControls,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Episode Title
                    Text(
                      episode.title,
                      style: DesignTokens.titleStyle.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    // Interactive Timeline Seek Bar (01:24 ━━━●━━━ 04:50)
                    VerticalSeekBar(
                      position: position,
                      duration: duration,
                      onSeek: onSeek,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
