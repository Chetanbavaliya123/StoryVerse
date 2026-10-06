import 'dart:math';
import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// Subtle floating dust/light particles using CustomPainter.
/// Wrapped in RepaintBoundary by the consumer for GPU efficiency.
class ParticlesPainter extends CustomPainter {
  ParticlesPainter({
    required this.animationValue,
    required this.particles,
  });

  final double animationValue;
  final List<OnboardingParticle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final progress = (animationValue + p.phaseOffset) % 1.0;
      final x = p.xRatio * size.width;
      // Drift upward: start from bottom offset, move up
      final y = size.height * (1.0 - progress * (1.0 + p.yRange)) +
          size.height * p.yStartOffset;

      // Fade in/out at edges
      double opacity = p.opacity;
      if (progress < 0.15) {
        opacity *= progress / 0.15;
      } else if (progress > 0.85) {
        opacity *= (1.0 - progress) / 0.15;
      }

      final paint = Paint()
        ..color = OBTokens.textPrimary.withValues(alpha: opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.radius * 0.5);

      canvas.drawCircle(Offset(x, y), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(ParticlesPainter oldDelegate) =>
      animationValue != oldDelegate.animationValue;
}

class OnboardingParticle {
  const OnboardingParticle({
    required this.xRatio,
    required this.yStartOffset,
    required this.yRange,
    required this.phaseOffset,
    required this.radius,
    required this.opacity,
  });

  final double xRatio;
  final double yStartOffset;
  final double yRange;
  final double phaseOffset;
  final double radius;
  final double opacity;
}

/// Pre-generates the particle list (pure data, no rebuilds).
List<OnboardingParticle> generateParticles(int count) {
  final rng = Random(42); // deterministic seed
  return List.generate(count, (_) {
    return OnboardingParticle(
      xRatio: rng.nextDouble(),
      yStartOffset: rng.nextDouble() * 0.3,
      yRange: 0.6 + rng.nextDouble() * 0.4,
      phaseOffset: rng.nextDouble(),
      radius: OBTokens.particleMinSize +
          rng.nextDouble() *
              (OBTokens.particleMaxSize - OBTokens.particleMinSize),
      opacity: OBTokens.particleMinOpacity +
          rng.nextDouble() *
              (OBTokens.particleMaxOpacity - OBTokens.particleMinOpacity),
    );
  });
}

/// Widget wrapper that creates and manages the particle animation loop.
class ParticlesOverlay extends StatefulWidget {
  const ParticlesOverlay({super.key, this.isActive = true});

  final bool isActive;

  @override
  State<ParticlesOverlay> createState() => _ParticlesOverlayState();
}

class _ParticlesOverlayState extends State<ParticlesOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<OnboardingParticle> _particles;

  @override
  void initState() {
    super.initState();
    _particles = generateParticles(OBTokens.particleCount);
    _controller = AnimationController(
      vsync: this,
      duration: OBTokens.particleDuration,
    );
    if (widget.isActive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(ParticlesOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isActive && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: ParticlesPainter(
              animationValue: _controller.value,
              particles: _particles,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}
