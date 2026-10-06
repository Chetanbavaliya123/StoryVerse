import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// Page 3 hero: floating phone-frame mockup with pulsing play button,
/// auto-filling progress bar, and 3 orbiting glass icon chips.
class OrbitingChipsHero extends StatefulWidget {
  const OrbitingChipsHero({
    super.key,
    this.isActive = true,
    this.reduceMotion = false,
  });

  final bool isActive;
  final bool reduceMotion;

  @override
  State<OrbitingChipsHero> createState() => _OrbitingChipsHeroState();
}

class _OrbitingChipsHeroState extends State<OrbitingChipsHero>
    with TickerProviderStateMixin {
  late final AnimationController _orbitController;
  late final AnimationController _progressController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _orbitController = AnimationController(
      vsync: this,
      duration: OBTokens.orbitDuration,
    );
    _progressController = AnimationController(
      vsync: this,
      duration: OBTokens.progressFillLoop,
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    if (widget.isActive && !widget.reduceMotion) {
      _orbitController.repeat();
      _progressController.repeat();
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(OrbitingChipsHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !widget.reduceMotion) {
      if (!_orbitController.isAnimating) _orbitController.repeat();
      if (!_progressController.isAnimating) _progressController.repeat();
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _orbitController.stop();
      _progressController.stop();
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _orbitController.dispose();
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final centerX = constraints.maxWidth / 2;
        final centerY = constraints.maxHeight / 2;

        return AnimatedBuilder(
          animation: Listenable.merge([
            _orbitController,
            _progressController,
            _pulseController,
          ]),
          builder: (context, _) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                // Phone frame mockup
                Positioned(
                  left: centerX - OBTokens.phoneWidth / 2,
                  top: centerY - OBTokens.phoneHeight / 2,
                  child: _buildPhoneFrame(),
                ),
                // Orbiting chips
                ..._buildOrbitingChips(centerX, centerY),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPhoneFrame() {
    return Container(
      width: OBTokens.phoneWidth,
      height: OBTokens.phoneHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(OBTokens.phoneRadius),
        border: Border.all(
          color: OBTokens.glassWhiteBorder,
          width: OBTokens.phoneBorderWidth,
        ),
        color: OBTokens.bgDeep,
        boxShadow: [
          BoxShadow(
            color: OBTokens.crimsonStart.withValues(alpha: 0.15),
            blurRadius: 30,
            spreadRadius: 5,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          OBTokens.phoneRadius - OBTokens.phoneBorderWidth,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Faux video background (gradient)
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF1A0A2E),
                    Color(0xFF0F0515),
                    OBTokens.bgDeep,
                  ],
                ),
              ),
            ),
            // Cinematic bars
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 30,
              child: Container(color: Colors.black.withValues(alpha: 0.5)),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 50,
              child: Container(color: Colors.black.withValues(alpha: 0.5)),
            ),
            // Pulsing play button
            Center(
              child: Transform.scale(
                scale: 1.0 +
                    (_pulseController.value * 0.1 *
                        (widget.reduceMotion ? 0 : 1)),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: OBTokens.crimsonStart.withValues(alpha: 0.9),
                    boxShadow: [
                      BoxShadow(
                        color: OBTokens.crimsonStart.withValues(alpha: 0.4),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: OBTokens.textPrimary,
                    size: 28,
                  ),
                ),
              ),
            ),
            // Progress bar at bottom
            Positioned(
              bottom: 16,
              left: 12,
              right: 12,
              child: Column(
                children: [
                  // Time labels
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatTime(
                            (_progressController.value * 180).round(),
                          ),
                          style: OBTokens.chipStyle.copyWith(fontSize: 9),
                        ),
                        Text(
                          '3:00',
                          style: OBTokens.chipStyle.copyWith(
                            fontSize: 9,
                            color: OBTokens.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Progress track
                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: OBTokens.glassWhiteSubtle,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: _progressController.value,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            gradient: OBTokens.ctaGradient,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Title at top
            Positioned(
              top: 38,
              left: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Midnight Chronicles',
                    style: OBTokens.posterTitleStyle.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Season 1 · Episode 3',
                    style: OBTokens.chipStyle.copyWith(
                      fontSize: 9,
                      color: OBTokens.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildOrbitingChips(double cx, double cy) {
    final chips = [
      (Icons.download_rounded, 'Download'),
      (Icons.bookmark_rounded, 'Watchlist'),
      (Icons.skip_next_rounded, 'Next Ep'),
    ];

    final orbitRadiusX = OBTokens.phoneWidth * 0.72;
    final orbitRadiusY = OBTokens.phoneHeight * 0.38;

    return List.generate(chips.length, (i) {
      final baseAngle = (i / chips.length) * 2 * pi;
      final angle = baseAngle +
          (widget.reduceMotion ? 0 : _orbitController.value * 2 * pi);

      final x = cx + cos(angle) * orbitRadiusX - 24;
      final y = cy + sin(angle) * orbitRadiusY - 18;

      return Positioned(
        left: x,
        top: y,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(OBTokens.radiusMD),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: OBTokens.glassBlur * 0.5,
              sigmaY: OBTokens.glassBlur * 0.5,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: OBTokens.spaceXS,
                vertical: OBTokens.spaceXS,
              ),
              decoration: BoxDecoration(
                color: OBTokens.glassWhiteFill,
                borderRadius: BorderRadius.circular(OBTokens.radiusMD),
                border: Border.all(
                  color: OBTokens.glassWhiteBorder,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    chips[i].$1,
                    size: 14,
                    color: OBTokens.textPrimary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    chips[i].$2,
                    style: OBTokens.chipStyle.copyWith(fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
