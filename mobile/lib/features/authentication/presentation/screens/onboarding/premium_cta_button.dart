import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'design_tokens.dart';
import 'animated_page_indicator.dart';

/// Premium CTA button with gradient, shimmer sweep, press scale+haptic,
/// progress ring, and morph from "Next >" to "Get Started →".
class PremiumCtaButton extends StatefulWidget {
  const PremiumCtaButton({
    super.key,
    required this.isLastPage,
    required this.onPressed,
    required this.pageOffset,
    required this.pageCount,
    this.reduceMotion = false,
  });

  final bool isLastPage;
  final VoidCallback onPressed;
  final double pageOffset;
  final int pageCount;
  final bool reduceMotion;

  @override
  State<PremiumCtaButton> createState() => _PremiumCtaButtonState();
}

class _PremiumCtaButtonState extends State<PremiumCtaButton>
    with TickerProviderStateMixin {
  late final AnimationController _shimmerController;
  late final AnimationController _arrowNudgeController;
  double _pressScale = 1.0;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: OBTokens.shimmerDuration,
    );
    _arrowNudgeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    if (!widget.reduceMotion) {
      _startShimmerLoop();
      if (widget.isLastPage) {
        _arrowNudgeController.repeat(reverse: true);
      }
    }
  }

  void _startShimmerLoop() {
    Future.delayed(OBTokens.shimmerInterval, () {
      if (!mounted) return;
      _shimmerController.forward(from: 0).then((_) {
        if (mounted) _startShimmerLoop();
      });
    });
  }

  @override
  void didUpdateWidget(PremiumCtaButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLastPage && !oldWidget.isLastPage && !widget.reduceMotion) {
      _arrowNudgeController.repeat(reverse: true);
    } else if (!widget.isLastPage && oldWidget.isLastPage) {
      _arrowNudgeController.stop();
      _arrowNudgeController.value = 0;
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _arrowNudgeController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    setState(() => _pressScale = OBTokens.ctaPressScale);
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails _) {
    setState(() => _pressScale = 1.0);
    widget.onPressed();
  }

  void _onTapCancel() {
    setState(() => _pressScale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final progress = (widget.pageOffset + 1) / widget.pageCount;
    final isLast = widget.isLastPage;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Progress ring around CTA
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: OBTokens.entryDefault,
          width: isLast ? OBTokens.ctaExpandedWidth + 16 : OBTokens.ctaMinWidth + 16,
          height: OBTokens.ctaHeight + 16,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Progress ring
              Positioned.fill(
                child: CustomPaint(
                  painter: ProgressRingPainter(
                    progress: progress,
                    strokeWidth: OBTokens.progressRingStroke,
                  ),
                ),
              ),
              // CTA Button
              Semantics(
                label: isLast ? 'Get Started' : 'Next page',
                button: true,
                child: GestureDetector(
                  onTapDown: _onTapDown,
                  onTapUp: _onTapUp,
                  onTapCancel: _onTapCancel,
                  child: AnimatedScale(
                    scale: _pressScale,
                    duration: const Duration(milliseconds: 100),
                    curve: OBTokens.ctaPress,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: OBTokens.entryDefault,
                      width: isLast
                          ? OBTokens.ctaExpandedWidth
                          : OBTokens.ctaMinWidth,
                      height: OBTokens.ctaHeight,
                      decoration: BoxDecoration(
                        gradient: OBTokens.ctaGradient,
                        borderRadius:
                            BorderRadius.circular(OBTokens.radiusPill),
                        boxShadow: [
                          BoxShadow(
                            color:
                                OBTokens.crimsonStart.withValues(alpha: 0.35),
                            blurRadius: 20,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(OBTokens.radiusPill),
                        child: Stack(
                          children: [
                            // Shimmer sweep
                            if (!widget.reduceMotion)
                              AnimatedBuilder(
                                animation: _shimmerController,
                                builder: (context, _) {
                                  return Positioned.fill(
                                    child: _ShimmerOverlay(
                                      progress: _shimmerController.value,
                                    ),
                                  );
                                },
                              ),
                            // Text content
                            Center(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                transitionBuilder: (child, animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0.1, 0),
                                        end: Offset.zero,
                                      ).animate(animation),
                                      child: child,
                                    ),
                                  );
                                },
                                child: isLast
                                    ? _buildGetStarted()
                                    : _buildNext(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNext() {
    return Row(
      key: const ValueKey('next'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Next', style: OBTokens.ctaTextStyle),
        const SizedBox(width: OBTokens.spaceXS),
        const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: OBTokens.textPrimary,
        ),
      ],
    );
  }

  Widget _buildGetStarted() {
    return AnimatedBuilder(
      animation: _arrowNudgeController,
      builder: (context, _) {
        final nudge = _arrowNudgeController.value * OBTokens.ctaArrowNudge;
        return Row(
          key: const ValueKey('getstarted'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Get Started', style: OBTokens.ctaTextStyle),
            const SizedBox(width: OBTokens.spaceXS),
            Transform.translate(
              offset: Offset(nudge, 0),
              child: const Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: OBTokens.textPrimary,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ShimmerOverlay extends StatelessWidget {
  const _ShimmerOverlay({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final shimmerWidth = width * 0.4;
        final start = -shimmerWidth + (width + shimmerWidth * 2) * progress;

        return Transform.translate(
          offset: Offset(start, 0),
          child: Container(
            width: shimmerWidth,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  OBTokens.shimmerBase,
                  OBTokens.shimmerHighlight,
                  OBTokens.shimmerBase,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
