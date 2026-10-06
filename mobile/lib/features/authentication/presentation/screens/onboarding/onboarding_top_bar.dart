import 'dart:ui';
import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// Premium glassmorphic top bar with logo mark + wordmark and animated Skip pill.
/// Persists across pages — does NOT rebuild per page.
class OnboardingTopBar extends StatelessWidget {
  const OnboardingTopBar({
    super.key,
    required this.showSkip,
    required this.onSkip,
    required this.entryAnimation,
  });

  final bool showSkip;
  final VoidCallback onSkip;
  final Animation<double> entryAnimation;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: OBTokens.spaceLG,
          vertical: OBTokens.spaceSM,
        ),
        child: SizedBox(
          height: OBTokens.topBarHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo + Wordmark
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -1.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: entryAnimation,
                  curve: const Interval(0.1, 0.5, curve: OBTokens.entryDefault),
                )),
                child: FadeTransition(
                  opacity: CurvedAnimation(
                    parent: entryAnimation,
                    curve: const Interval(0.1, 0.45),
                  ),
                  child: const _LogoWordmark(),
                ),
              ),

              // Skip pill — animated visibility
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.3, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: OBTokens.entryDefault,
                    )),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: showSkip
                    ? _SkipPill(key: const ValueKey('skip'), onTap: onSkip)
                    : const SizedBox.shrink(key: ValueKey('empty')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoWordmark extends StatelessWidget {
  const _LogoWordmark();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Glass logo mark
        ClipRRect(
          borderRadius: BorderRadius.circular(OBTokens.radiusXS),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: OBTokens.glassBlur,
              sigmaY: OBTokens.glassBlur,
            ),
            child: Container(
              width: OBTokens.logoMarkSize,
              height: OBTokens.logoMarkSize,
              decoration: BoxDecoration(
                color: OBTokens.glassWhiteFill,
                borderRadius: BorderRadius.circular(OBTokens.radiusXS),
                border: Border.all(color: OBTokens.glassWhiteBorder, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: OBTokens.crimsonStart.withValues(alpha: 0.15),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Center(
                child: ShaderMask(
                  shaderCallback: (bounds) =>
                      OBTokens.redTextGradient.createShader(bounds),
                  child: Text(
                    'SV',
                    style: OBTokens.logoSVStyle.copyWith(
                      color: OBTokens.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: OBTokens.spaceXS),
        // Wordmark
        Text('STORYVERSE', style: OBTokens.wordmarkStyle),
        // Glowing red dot
        Container(
          width: 5,
          height: 5,
          margin: const EdgeInsets.only(left: 2, bottom: 8),
          decoration: BoxDecoration(
            color: OBTokens.crimsonStart,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: OBTokens.crimsonStart.withValues(alpha: 0.6),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SkipPill extends StatelessWidget {
  const _SkipPill({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Skip onboarding',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(OBTokens.radiusFull),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: OBTokens.glassBlur,
              sigmaY: OBTokens.glassBlur,
            ),
            child: Container(
              height: OBTokens.skipPillHeight,
              padding: const EdgeInsets.symmetric(
                horizontal: OBTokens.spaceMD,
              ),
              decoration: BoxDecoration(
                color: OBTokens.glassWhiteFill,
                borderRadius: BorderRadius.circular(OBTokens.radiusFull),
                border:
                    Border.all(color: OBTokens.glassWhiteBorder, width: 1),
              ),
              child: Center(
                child: Text('SKIP', style: OBTokens.skipStyle),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
