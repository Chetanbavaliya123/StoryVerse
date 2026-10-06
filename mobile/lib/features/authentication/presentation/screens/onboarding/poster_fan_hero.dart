import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// Page 2 hero: 3D-tilted fan/stack of 5 portrait poster cards.
/// Center card larger, side cards rotated with perspective.
/// Idle sine-wave bobbing + react to swipe progress.
class PosterFanHero extends StatefulWidget {
  const PosterFanHero({
    super.key,
    required this.pageOffset,
    this.isActive = true,
    this.reduceMotion = false,
  });

  final double pageOffset; // how far into this page (0 = centered, -1/+1 = off)
  final bool isActive;
  final bool reduceMotion;

  @override
  State<PosterFanHero> createState() => _PosterFanHeroState();
}

class _PosterFanHeroState extends State<PosterFanHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bobController;

  // 5 poster assets from existing story images
  static const List<String> _posterAssets = [
    'assets/images/stories/story_03.jpg',
    'assets/images/stories/story_05.jpg',
    'assets/images/stories/story_08.jpg',
    'assets/images/stories/story_12.jpg',
    'assets/images/stories/story_14.jpg',
  ];

  static const List<String> _posterTitles = [
    'Midnight Run',
    'Lost City',
    'Dark Forest',
    'Ocean Deep',
    'Star Bound',
  ];

  @override
  void initState() {
    super.initState();
    _bobController = AnimationController(
      vsync: this,
      duration: OBTokens.bobbingDuration,
    );
    if (widget.isActive && !widget.reduceMotion) {
      _bobController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PosterFanHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !widget.reduceMotion && !_bobController.isAnimating) {
      _bobController.repeat(reverse: true);
    } else if ((!widget.isActive || widget.reduceMotion) &&
        _bobController.isAnimating) {
      _bobController.stop();
    }
  }

  @override
  void dispose() {
    _bobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final centerX = constraints.maxWidth / 2;
        final centerY = constraints.maxHeight / 2;

        return AnimatedBuilder(
          animation: _bobController,
          builder: (context, _) {
            return Stack(
              clipBehavior: Clip.none,
              children: List.generate(_posterAssets.length, (i) {
                return _buildPosterCard(
                  index: i,
                  total: _posterAssets.length,
                  centerX: centerX,
                  centerY: centerY,
                  constraints: constraints,
                );
              }),
            );
          },
        );
      },
    );
  }

  Widget _buildPosterCard({
    required int index,
    required int total,
    required double centerX,
    required double centerY,
    required BoxConstraints constraints,
  }) {
    final centerIndex = total ~/ 2;
    final offset = index - centerIndex;
    final isCenter = offset == 0;

    // Card sizing
    final cardW = isCenter
        ? OBTokens.posterWidth * OBTokens.posterCenterScale
        : OBTokens.posterWidth;
    final cardH = isCenter
        ? OBTokens.posterHeight * OBTokens.posterCenterScale
        : OBTokens.posterHeight;

    // Rotation: side cards rotate, more for outer cards
    final rotation =
        offset * OBTokens.posterSideRotation * (pi / 180);

    // Horizontal position: fan spread
    final spreadFactor = widget.pageOffset.abs().clamp(0.0, 1.0);
    final baseSpacing = cardW * 0.55;
    final extraSpread = spreadFactor * 15.0;
    final xPos = centerX - cardW / 2 + offset * (baseSpacing + extraSpread);

    // Bobbing: staggered sine wave per card
    final bobPhase = (index / total) * 2 * pi;
    final bobValue =
        widget.reduceMotion ? 0.0 : sin(_bobController.value * pi + bobPhase);
    final bobOffset = bobValue * 6.0;

    // Y position with bob
    final yPos = centerY - cardH / 2 + bobOffset;

    return Positioned(
      left: xPos,
      top: yPos,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001) // perspective
          ..rotateZ(rotation),
        child: Container(
          width: cardW,
          height: cardH,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(OBTokens.radiusXL),
            border: Border.all(
              color: OBTokens.posterBorder,
              width: 1.5,
            ),
            boxShadow: [
              if (isCenter)
                BoxShadow(
                  color: OBTokens.posterGlow,
                  blurRadius: 30,
                  spreadRadius: 4,
                ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(OBTokens.radiusXL),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  _posterAssets[index],
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, e, _) => _buildGradientFallback(index),
                ),
                // Bottom gradient for title
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: cardH * 0.45,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.8),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Poster title + play icon
                Positioned(
                  bottom: OBTokens.spaceSM,
                  left: OBTokens.spaceSM,
                  right: OBTokens.spaceSM,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.play_circle_filled_rounded,
                        size: 18,
                        color: OBTokens.textPrimary,
                      ),
                      const SizedBox(width: OBTokens.spaceXXS),
                      Expanded(
                        child: Text(
                          _posterTitles[index],
                          style: OBTokens.posterTitleStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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

  Widget _buildGradientFallback(int index) {
    final gradients = [
      [const Color(0xFFFF0080), const Color(0xFFFF8C00)],
      [const Color(0xFF8E2DE2), const Color(0xFF4A00E0)],
      [const Color(0xFFED213A), const Color(0xFF93291E)],
      [const Color(0xFF00C6FF), const Color(0xFF0072FF)],
      [const Color(0xFF11998E), const Color(0xFF38EF7D)],
    ];
    final g = gradients[index % gradients.length];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: g,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.play_arrow_rounded,
          size: 36,
          color: Colors.white.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}

/// Floating glass episode chips that pop in with elastic animation.
class FloatingEpisodeChips extends StatefulWidget {
  const FloatingEpisodeChips({
    super.key,
    required this.isVisible,
    this.reduceMotion = false,
  });

  final bool isVisible;
  final bool reduceMotion;

  @override
  State<FloatingEpisodeChips> createState() => _FloatingEpisodeChipsState();
}

class _FloatingEpisodeChipsState extends State<FloatingEpisodeChips>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: OBTokens.chipPopDuration,
    );
    if (widget.isVisible) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(FloatingEpisodeChips oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _controller.forward(from: 0);
    } else if (!widget.isVisible && oldWidget.isVisible) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.reduceMotion) {
      return _buildChipsStatic();
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Stack(
          children: [
            _buildChip('EP 01', 0, const Alignment(-0.7, -0.5)),
            _buildChip('EP 02', 1, const Alignment(0.65, -0.3)),
            _buildChip('EP 03', 2, const Alignment(-0.4, 0.5)),
            _buildBadge('NEW EPISODE', 3, const Alignment(0.5, 0.55)),
          ],
        );
      },
    );
  }

  Widget _buildChip(String label, int index, Alignment alignment) {
    final delay = index * 0.15;
    final start = delay;
    final end = (start + 0.6).clamp(0.0, 1.0);
    final interval = Interval(start, end, curve: OBTokens.chipPop);
    final scale = interval.transform(_controller.value);

    return Align(
      alignment: alignment,
      child: Transform.scale(
        scale: scale,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(OBTokens.radiusMD),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: OBTokens.glassBlur * 0.6,
              sigmaY: OBTokens.glassBlur * 0.6,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: OBTokens.spaceSM,
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
              child: Text(label, style: OBTokens.chipStyle),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, int index, Alignment alignment) {
    final delay = index * 0.15;
    final start = delay;
    final end = (start + 0.6).clamp(0.0, 1.0);
    final interval = Interval(start, end, curve: OBTokens.chipPop);
    final scale = interval.transform(_controller.value);

    return Align(
      alignment: alignment,
      child: Transform.scale(
        scale: scale,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: OBTokens.spaceSM,
            vertical: OBTokens.spaceXS,
          ),
          decoration: BoxDecoration(
            gradient: OBTokens.ctaGradient,
            borderRadius: BorderRadius.circular(OBTokens.radiusSM),
            boxShadow: [
              BoxShadow(
                color: OBTokens.crimsonStart.withValues(alpha: 0.3),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Text(label, style: OBTokens.badgeStyle),
        ),
      ),
    );
  }

  Widget _buildChipsStatic() {
    return Stack(
      children: [
        _buildChipStatic('EP 01', const Alignment(-0.7, -0.5)),
        _buildChipStatic('EP 02', const Alignment(0.65, -0.3)),
        _buildChipStatic('EP 03', const Alignment(-0.4, 0.5)),
        Align(
          alignment: const Alignment(0.5, 0.55),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: OBTokens.spaceSM,
              vertical: OBTokens.spaceXS,
            ),
            decoration: BoxDecoration(
              gradient: OBTokens.ctaGradient,
              borderRadius: BorderRadius.circular(OBTokens.radiusSM),
            ),
            child: Text('NEW EPISODE', style: OBTokens.badgeStyle),
          ),
        ),
      ],
    );
  }

  Widget _buildChipStatic(String label, Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: OBTokens.spaceSM,
          vertical: OBTokens.spaceXS,
        ),
        decoration: BoxDecoration(
          color: OBTokens.glassWhiteFill,
          borderRadius: BorderRadius.circular(OBTokens.radiusMD),
          border: Border.all(color: OBTokens.glassWhiteBorder, width: 1),
        ),
        child: Text(label, style: OBTokens.chipStyle),
      ),
    );
  }
}
