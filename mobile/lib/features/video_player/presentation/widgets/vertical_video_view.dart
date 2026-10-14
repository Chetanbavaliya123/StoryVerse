import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:storyverse/core/theme/design_tokens.dart';
import 'package:storyverse/core/widgets/network_image_with_fallback.dart';

class VerticalVideoView extends StatelessWidget {
  final VideoPlayerController? controller;
  final String thumbnailUrl;
  final bool isLoading;
  final bool hasError;
  final String errorMessage;
  final VoidCallback onRetry;
  final Widget overlay;
  final bool isCinematicLetterbox;

  const VerticalVideoView({
    super.key,
    required this.controller,
    required this.thumbnailUrl,
    required this.isLoading,
    required this.hasError,
    required this.errorMessage,
    required this.onRetry,
    required this.overlay,
    this.isCinematicLetterbox = false,
  });

  @override
  Widget build(BuildContext context) {
    final isInitialized = controller != null && controller!.value.isInitialized;

    return Container(
      color: Colors.black,
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Ambient Blurred Backdrop (only in discovery / shorts mode)
          if (!isCinematicLetterbox && thumbnailUrl.isNotEmpty)
            NetworkImageWithFallback(
              imageUrl: thumbnailUrl,
              fit: BoxFit.cover,
            ),

          if (!isCinematicLetterbox && thumbnailUrl.isNotEmpty)
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                color: Colors.black.withValues(alpha: 0.65),
              ),
            ),

          // 2. Main Video Layer (BoxFit.cover for Shorts, AspectRatio for Cinematic Letterbox)
          if (isInitialized && !hasError)
            Center(
              child: isCinematicLetterbox
                  ? AspectRatio(
                      aspectRatio: controller!.value.aspectRatio,
                      child: VideoPlayer(controller!),
                    )
                  : SizedBox.expand(
                      child: FittedBox(
                        fit: BoxFit.cover,
                        clipBehavior: Clip.hardEdge,
                        child: SizedBox(
                          width: controller!.value.size.width > 0
                              ? controller!.value.size.width
                              : 1080,
                          height: controller!.value.size.height > 0
                              ? controller!.value.size.height
                              : 1920,
                          child: VideoPlayer(controller!),
                        ),
                      ),
                    ),
            ),

          // 3. Loading State
          if (isLoading || !isInitialized && !hasError)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      color: DesignTokens.primaryAccent,
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Loading episode...',
                    style: DesignTokens.bodyStyle.copyWith(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

          // 4. Buffering State
          if (isInitialized && controller!.value.isBuffering && !isLoading)
            const Center(
              child: SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  color: DesignTokens.primaryAccent,
                  strokeWidth: 3,
                ),
              ),
            ),

          // 5. Error State
          if (hasError)
            Container(
              color: Colors.black.withValues(alpha: 0.85),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: DesignTokens.primaryAccent,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        errorMessage.isNotEmpty
                            ? errorMessage
                            : 'Unable to play this episode',
                        style: DesignTokens.bodyStyle.copyWith(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DesignTokens.primaryAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 6. Interactive Controls & UI Overlay
          overlay,
        ],
      ),
    );
  }
}
