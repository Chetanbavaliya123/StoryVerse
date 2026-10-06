import 'dart:math';
import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// Animated mesh-like gradient background with slow-moving blurred orbs.
/// Colors interpolate smoothly based on [pageOffset] for a unified color journey.
class AnimatedGradientBackground extends StatefulWidget {
  const AnimatedGradientBackground({
    super.key,
    required this.pageOffset,
    this.isActive = true,
    this.reduceMotion = false,
  });

  final double pageOffset; // 0.0 = page0, 1.0 = page1, 2.0 = page2
  final bool isActive;
  final bool reduceMotion;

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: OBTokens.orbDuration,
    );
    if (widget.isActive && !widget.reduceMotion) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(AnimatedGradientBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !widget.reduceMotion && !_controller.isAnimating) {
      _controller.repeat();
    } else if ((!widget.isActive || widget.reduceMotion) &&
        _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _lerpPageColor(List<Color> stops, double offset) {
    final clamped = offset.clamp(0.0, 2.0);
    if (clamped <= 1.0) {
      return Color.lerp(stops[0], stops[1], clamped)!;
    }
    return Color.lerp(stops[1], stops[2], clamped - 1.0)!;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final primary =
            _lerpPageColor(OBTokens.pageBackgrounds, widget.pageOffset);
        final secondary =
            _lerpPageColor(OBTokens.pageBackgroundsSecondary, widget.pageOffset);

        return RepaintBoundary(
          child: CustomPaint(
            painter: _OrbGradientPainter(
              primary: primary,
              secondary: secondary,
              time: _controller.value,
              reduceMotion: widget.reduceMotion,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }
}

class _OrbGradientPainter extends CustomPainter {
  _OrbGradientPainter({
    required this.primary,
    required this.secondary,
    required this.time,
    required this.reduceMotion,
  });

  final Color primary;
  final Color secondary;
  final double time;
  final bool reduceMotion;

  @override
  void paint(Canvas canvas, Size size) {
    // Base gradient fill
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primary, OBTokens.bgDeep],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    if (reduceMotion) return;

    // 3 slow-moving blurred orbs
    final orbData = [
      _OrbData(
        cxRatio: 0.3,
        cyRatio: 0.25,
        radiusRatio: 0.35,
        color: secondary.withValues(alpha: 0.25),
        speedMultiplier: 1.0,
      ),
      _OrbData(
        cxRatio: 0.7,
        cyRatio: 0.55,
        radiusRatio: 0.28,
        color: OBTokens.violetAccent.withValues(alpha: 0.15),
        speedMultiplier: 0.7,
      ),
      _OrbData(
        cxRatio: 0.5,
        cyRatio: 0.75,
        radiusRatio: 0.32,
        color: OBTokens.crimsonStart.withValues(alpha: 0.12),
        speedMultiplier: 1.3,
      ),
    ];

    for (final orb in orbData) {
      final angle = time * 2 * pi * orb.speedMultiplier;
      final cx = size.width * orb.cxRatio + sin(angle) * size.width * 0.06;
      final cy = size.height * orb.cyRatio + cos(angle) * size.height * 0.04;
      final radius = size.width * orb.radiusRatio;

      final orbPaint = Paint()
        ..shader = RadialGradient(
          colors: [orb.color, orb.color.withValues(alpha: 0)],
        ).createShader(
          Rect.fromCircle(center: Offset(cx, cy), radius: radius),
        )
        ..maskFilter =
            const MaskFilter.blur(BlurStyle.normal, OBTokens.backgroundOrbBlur);

      canvas.drawCircle(Offset(cx, cy), radius, orbPaint);
    }
  }

  @override
  bool shouldRepaint(_OrbGradientPainter old) =>
      primary != old.primary ||
      secondary != old.secondary ||
      time != old.time;
}

class _OrbData {
  const _OrbData({
    required this.cxRatio,
    required this.cyRatio,
    required this.radiusRatio,
    required this.color,
    required this.speedMultiplier,
  });
  final double cxRatio;
  final double cyRatio;
  final double radiusRatio;
  final Color color;
  final double speedMultiplier;
}
