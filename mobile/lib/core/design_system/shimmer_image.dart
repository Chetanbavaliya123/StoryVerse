import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ShimmerImage extends StatefulWidget {
  final String imageUrl;
  final String? title;
  final String? genre;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const ShimmerImage({
    super.key,
    required this.imageUrl,
    this.title,
    this.genre,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  State<ShimmerImage> createState() => _ShimmerImageState();
}

class _ShimmerImageState extends State<ShimmerImage>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController.unbounded(vsync: this)
      ..repeat(min: -0.5, max: 1.5, period: const Duration(milliseconds: 1400));
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  List<Color> _getGenreGradient(String? genre) {
    final g = (genre ?? '').toLowerCase();
    if (g.contains('horror')) {
      return const [Color(0xFF2E0814), Color(0xFF130006)];
    } else if (g.contains('romance')) {
      return const [Color(0xFF881337), Color(0xFF3F0415)];
    } else if (g.contains('thriller') || g.contains('crime')) {
      return const [Color(0xFF1E1B4B), Color(0xFF0F172A)];
    } else if (g.contains('comedy')) {
      return const [Color(0xFF78350F), Color(0xFF291503)];
    } else if (g.contains('sci-fi') || g.contains('scifi') || g.contains('fantasy')) {
      return const [Color(0xFF0C4A6E), Color(0xFF032238)];
    } else {
      return const [Color(0xFF27272A), Color(0xFF18181B)];
    }
  }

  String _getInitials(String? title) {
    if (title == null || title.trim().isEmpty) return 'SV';
    final parts = title.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Widget _buildShimmer() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              begin: Alignment(-1.0 + _shimmerController.value, -0.3),
              end: Alignment(1.0 + _shimmerController.value, 0.3),
              colors: const [
                Color(0xFF1A1A20),
                Color(0xFF2E2E38),
                Color(0xFF1A1A20),
              ],
              stops: const [0.1, 0.5, 0.9],
            ),
          ),
          child: Center(
            child: Icon(
              Icons.movie_creation_outlined,
              size: (widget.width != null && widget.width! < 100) ? 18 : 28,
              color: Colors.white12,
            ),
          ),
        );
      },
    );
  }

  Widget _buildFallback() {
    final gradient = _getGenreGradient(widget.genre);
    final initials = _getInitials(widget.title);

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                  width: 1,
                ),
              ),
              child: Text(
                initials,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: (widget.width != null && widget.width! < 100) ? 14 : 20,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            if (widget.genre != null && (widget.height == null || widget.height! > 120)) ...[
              const SizedBox(height: 6),
              Text(
                widget.genre!.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrl.isEmpty) {
      return _buildFallback();
    }

    final isAsset = widget.imageUrl.startsWith('assets/');

    Widget image;
    if (isAsset) {
      image = Image.asset(
        widget.imageUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    } else {
      image = CachedNetworkImage(
        imageUrl: widget.imageUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        placeholder: (context, url) => _buildShimmer(),
        errorWidget: (context, url, error) => _buildFallback(),
      );
    }

    if (widget.borderRadius != null) {
      image = ClipRRect(
        borderRadius: widget.borderRadius!,
        child: image,
      );
    }

    return image;
  }
}
