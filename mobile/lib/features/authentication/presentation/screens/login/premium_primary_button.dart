import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../onboarding/design_tokens.dart';

class PremiumPrimaryButton extends StatefulWidget {
  const PremiumPrimaryButton({
    super.key,
    required this.text,
    required this.isLoading,
    required this.isDisabled,
    required this.onPressed,
  });

  final String text;
  final bool isLoading;
  final bool isDisabled;
  final VoidCallback onPressed;

  @override
  State<PremiumPrimaryButton> createState() => _PremiumPrimaryButtonState();
}

class _PremiumPrimaryButtonState extends State<PremiumPrimaryButton>
    with TickerProviderStateMixin {
  late final AnimationController _shimmerController;
  late final AnimationController _arrowController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _arrowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _arrowController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.isDisabled || widget.isLoading) return;
    setState(() => _isPressed = true);
    HapticFeedback.lightImpact();
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.isDisabled || widget.isLoading) return;
    setState(() => _isPressed = false);
    widget.onPressed();
  }

  void _handleTapCancel() {
    if (widget.isDisabled || widget.isLoading) return;
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final scale = _isPressed ? 0.96 : 1.0;
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        behavior: HitTestBehavior.opaque,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: widget.isDisabled ? 0.5 : 1.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: OBTokens.entryDefault,
            height: 56,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: OBTokens.ctaGradient,
              boxShadow: widget.isDisabled || widget.isLoading
                  ? []
                  : [
                      BoxShadow(
                        color: OBTokens.crimsonStart.withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Shimmer sweep
                  if (!widget.isDisabled && !widget.isLoading && !disableAnimations)
                    AnimatedBuilder(
                      animation: _shimmerController,
                      builder: (context, child) {
                        final val = _shimmerController.value;
                        // Shimmer happens in the first 30% of the duration
                        if (val > 0.3) return const SizedBox();
                        
                        final progress = val / 0.3; // 0 to 1
                        return Positioned.fill(
                          child: FractionallySizedBox(
                            widthFactor: 2.0,
                            alignment: Alignment(-1.0 + progress * 2.0, 0),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withValues(alpha: 0.0),
                                    Colors.white.withValues(alpha: 0.3),
                                    Colors.white.withValues(alpha: 0.0),
                                  ],
                                  stops: const [0.4, 0.5, 0.6],
                                  transform: const GradientRotation(0.3),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  
                  // Content
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: widget.isLoading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Signing In...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.text,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white, // Full opacity
                                ),
                              ),
                              const SizedBox(width: 8),
                              AnimatedBuilder(
                                animation: _arrowController,
                                builder: (context, child) {
                                  final nudge = disableAnimations ? 0.0 : _arrowController.value;
                                  return Transform.translate(
                                    offset: Offset(nudge * 4.0, 0),
                                    child: child,
                                  );
                                },
                                child: const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white, // Full opacity
                                  size: 18,
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
      ),
    );
  }
}
