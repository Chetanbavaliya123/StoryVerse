import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:storyverse/core/theme/app_colors.dart';
import 'package:storyverse/core/widgets/storyverse_logo.dart';

class NetworkImageWithFallback extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  const NetworkImageWithFallback({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAsset = imageUrl.startsWith('assets/');

    Widget imageWidget;
    if (isAsset) {
      imageWidget = Image.asset(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        filterQuality: FilterQuality.high,
        errorBuilder: _buildError,
      );
    } else {
      imageWidget = CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        filterQuality: FilterQuality.high,
        placeholder: (context, url) => _buildPlaceholder(),
        errorWidget: (context, url, error) => _buildError(context, error, null),
      );
    }

    return imageWidget;
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.primarySurface,
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.primaryAccent),
      ),
    );
  }

  Widget _buildError(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    // Generate deterministic colors based on imageUrl hash
    final int hash = imageUrl.hashCode;

    // Some beautiful modern gradients
    final List<List<Color>> gradients = [
      [const Color(0xFFFF0080), const Color(0xFFFF8C00)], // Pink-Orange
      [const Color(0xFF00C6FF), const Color(0xFF0072FF)], // Blue
      [const Color(0xFF11998E), const Color(0xFF38EF7D)], // Green
      [const Color(0xFF8E2DE2), const Color(0xFF4A00E0)], // Purple
      [const Color(0xFFFC466B), const Color(0xFF3F5EFB)], // Pink-Blue
      [const Color(0xFFFDC830), const Color(0xFFF37335)], // Yellow-Orange
      [const Color(0xFF00B4DB), const Color(0xFF0083B0)], // Light Blue
      [const Color(0xFFED213A), const Color(0xFF93291E)], // Red
    ];

    final gradient = gradients[hash.abs() % gradients.length];

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
      ),
      child: Center(
        child: Opacity(
          opacity: 0.8,
          child: StoryVerseLogo(
            size: (width != null && width! < 60) ? width! * 0.5 : 48,
          ),
        ),
      ),
    );
  }
}
