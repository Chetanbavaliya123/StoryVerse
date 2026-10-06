import 'dart:math';
import 'package:flutter/material.dart';
import '../onboarding/design_tokens.dart';

class LoginBackground extends StatefulWidget {
  const LoginBackground({super.key});

  @override
  State<LoginBackground> createState() => _LoginBackgroundState();
}

class _LoginBackgroundState extends State<LoginBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    if (disableAnimations) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }

    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: OBTokens.bgDeep),
          
          // Drifting orbs
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _LoginBackgroundPainter(
                  animationValue: _controller.value,
                ),
              );
            },
          ),
          // Vignette
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                colors: [Colors.transparent, Colors.black87],
                radius: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginBackgroundPainter extends CustomPainter {
  const _LoginBackgroundPainter({required this.animationValue});
  final double animationValue;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final t = animationValue * 2 * pi;

    // Orb 1: Crimson top-leftish
    final cx1 = w * 0.3 + sin(t) * w * 0.2;
    final cy1 = h * 0.2 + cos(t * 0.8) * h * 0.1;
    final paint1 = Paint()
      ..shader = RadialGradient(
        colors: [
          OBTokens.crimsonStart.withValues(alpha: 0.18),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx1, cy1), radius: w * 0.8));
    canvas.drawCircle(Offset(cx1, cy1), w * 0.8, paint1);

    // Orb 2: Violet top-rightish
    final cx2 = w * 0.8 + cos(t * 1.2) * w * 0.15;
    final cy2 = h * 0.3 + sin(t * 0.9) * h * 0.15;
    final paint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF6D28D9).withValues(alpha: 0.14),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx2, cy2), radius: w * 0.7));
    canvas.drawCircle(Offset(cx2, cy2), w * 0.7, paint2);
  }

  @override
  bool shouldRepaint(_LoginBackgroundPainter old) =>
      animationValue != old.animationValue;
}
