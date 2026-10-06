import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// Full-bleed cinematic image with slow Ken Burns effect
/// (scale 1.0 → 1.12 + slight pan, 12s loop, easeInOut).
/// Also applies layered gradient scrims for text readability.
class KenBurnsBackground extends StatefulWidget {
  const KenBurnsBackground({
    super.key,
    required this.imageUrl,
    this.parallaxOffset = 0.0,
    this.isActive = true,
    this.reduceMotion = false,
  });

  final String imageUrl;
  final double parallaxOffset; // from PageController for parallax
  final bool isActive;
  final bool reduceMotion;

  @override
  State<KenBurnsBackground> createState() => _KenBurnsBackgroundState();
}

class _KenBurnsBackgroundState extends State<KenBurnsBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _panAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: OBTokens.kenBurnsDuration,
    );

    _scaleAnimation = Tween<double>(
      begin: OBTokens.kenBurnsScaleStart,
      end: OBTokens.kenBurnsScaleEnd,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _panAnimation = Tween<Offset>(
      begin: OBTokens.kenBurnsPanStart,
      end: OBTokens.kenBurnsPanEnd,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.isActive && !widget.reduceMotion) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(KenBurnsBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !widget.reduceMotion && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
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

  Matrix4 _buildTransform(double scale, double dx, double dy) {
    // Build scale + translate transform without deprecated methods
    return Matrix4(
      scale, 0, 0, 0,
      0, scale, 0, 0,
      0, 0, 1, 0,
      dx, dy, 0, 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNetwork = widget.imageUrl.startsWith('http');

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = widget.reduceMotion ? 1.0 : _scaleAnimation.value;
        final pan = widget.reduceMotion ? Offset.zero : _panAnimation.value;
        // Parallax offset: image moves slower than text
        final parallax = widget.parallaxOffset * 30.0;

        return Stack(
          fit: StackFit.expand,
          children: [
            // Cinematic image with Ken Burns
            Transform(
              alignment: Alignment.center,
              transform: _buildTransform(scale, pan.dx + parallax, pan.dy),
              child: child,
            ),
            // Top gradient scrim
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                  colors: [
                    OBTokens.bgDeep.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            // Bottom heavy gradient scrim
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  stops: const [0.0, 0.35, 0.65],
                  colors: [
                    OBTokens.bgDeep,
                    OBTokens.bgDeep.withValues(alpha: 0.85),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            // Subtle vignette overlay
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.0,
                  colors: [
                    Colors.transparent,
                    OBTokens.bgDeep.withValues(alpha: 0.4),
                  ],
                ),
              ),
            ),
          ],
        );
      },
      child: isNetwork
          ? Image.network(
              widget.imageUrl,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
              errorBuilder: (_, e, _) => Container(color: OBTokens.bgDeep),
            )
          : Image.asset(
              widget.imageUrl,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
              errorBuilder: (_, e, _) => Container(color: OBTokens.bgDeep),
            ),
    );
  }
}
