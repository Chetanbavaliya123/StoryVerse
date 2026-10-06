import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:storyverse/core/theme/design_tokens.dart';

class PremiumVideoPlayer extends StatelessWidget {
  final VideoPlayerController? controller;
  final String thumbnailUrl;
  final bool isLoading;
  final bool hasError;
  final Widget? errorWidget;
  final Widget? controlsOverlay;
  final Widget? completionOverlay;

  const PremiumVideoPlayer({
    super.key,
    required this.controller,
    required this.thumbnailUrl,
    this.isLoading = false,
    this.hasError = false,
    this.errorWidget,
    this.controlsOverlay,
    this.completionOverlay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      width: double.infinity,
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            alignment: Alignment.center,
            fit: StackFit.expand,
            children: [
              // Ambient Backdrop
              if (thumbnailUrl.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(thumbnailUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                  ),
                )
              else
                Container(color: Colors.black),
                
              if (hasError)
                errorWidget ?? const SizedBox.shrink()
              else if (isLoading || controller == null || !controller!.value.isInitialized)
                _buildLoadingState()
              else ...[
                // Video Content
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: DesignTokens.glowShadow,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                          controller!.value.aspectRatio < 1 ? DesignTokens.radiusMedium : 0),
                      child: AspectRatio(
                        aspectRatio: controller!.value.aspectRatio,
                        child: VideoPlayer(controller!),
                      ),
                    ),
                  ),
                ),
                // Buffering indicator
                if (controller!.value.isBuffering)
                  Center(
                    child: CircularProgressIndicator(
                      color: DesignTokens.primaryAccent,
                      strokeWidth: 3,
                    ),
                  ),
                // Overlays
                completionOverlay ?? controlsOverlay ?? const SizedBox.shrink(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: Colors.black45,
      child: Center(
        child: CircularProgressIndicator(
          color: DesignTokens.primaryAccent,
          strokeWidth: 3,
        ),
      ),
    );
  }
}
