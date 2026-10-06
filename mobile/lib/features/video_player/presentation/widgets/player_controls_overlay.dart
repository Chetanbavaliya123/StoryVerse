import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:storyverse/core/theme/design_tokens.dart';
import 'package:storyverse/features/video_player/presentation/widgets/premium_seek_bar.dart';

class PlayerControlsOverlay extends StatelessWidget {
  final VideoPlayerController controller;
  final String title;
  final bool showControls;
  final bool isFullscreen;
  final VoidCallback onToggleControls;
  final VoidCallback onTogglePlayPause;
  final VoidCallback onSeekForward;
  final VoidCallback onSeekBackward;
  final VoidCallback onToggleFullscreen;
  final VoidCallback onBack;

  const PlayerControlsOverlay({
    super.key,
    required this.controller,
    required this.title,
    required this.showControls,
    required this.isFullscreen,
    required this.onToggleControls,
    required this.onTogglePlayPause,
    required this.onSeekForward,
    required this.onSeekBackward,
    required this.onToggleFullscreen,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggleControls,
      onDoubleTapDown: (details) {
        final screenWidth = MediaQuery.of(context).size.width;
        if (details.globalPosition.dx < screenWidth / 2) {
          onSeekBackward();
        } else {
          onSeekForward();
        }
      },
      child: AnimatedOpacity(
        opacity: showControls ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                DesignTokens.background.withValues(alpha: 0.8),
                Colors.transparent,
                Colors.transparent,
                DesignTokens.background.withValues(alpha: 0.9),
              ],
              stops: const [0.0, 0.3, 0.7, 1.0],
            ),
          ),
          child: IgnorePointer(
            ignoring: !showControls,
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: DesignTokens.surfaceGlass,
                              padding: const EdgeInsets.all(12),
                            ),
                            onPressed: onBack,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          title,
                          style: DesignTokens.sectionHeadingStyle.copyWith(
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.more_vert,
                          color: Colors.white,
                          size: 24,
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                // Center controls
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _controlButton(Icons.replay_10_rounded, onSeekBackward, size: 36),
                    const SizedBox(width: 32),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(40),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            onTogglePlayPause();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: DesignTokens.surfaceGlass,
                              shape: BoxShape.circle,
                              border: Border.all(color: DesignTokens.surfaceGlassBorder),
                            ),
                            child: Icon(
                              controller.value.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 32),
                    _controlButton(Icons.forward_10_rounded, onSeekForward, size: 36),
                  ],
                ),
                const Spacer(),
                // Bottom controls
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: PremiumSeekBar(
                    position: controller.value.position,
                    duration: controller.value.duration,
                    onChanged: (value) {
                      controller.seekTo(value);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.speed_rounded, color: Colors.white),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: Icon(
                          isFullscreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                          color: Colors.white,
                        ),
                        onPressed: onToggleFullscreen,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _controlButton(IconData icon, VoidCallback onTap, {double size = 40}) {
    return IconButton(
      onPressed: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      icon: Icon(icon, color: Colors.white, size: size),
    );
  }
}
