import 'dart:ui';
import 'package:flutter/material.dart';
import '../onboarding/design_tokens.dart';

void showGlassToast(
  BuildContext context, {
  required String message,
  bool isError = true,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => _GlassToastWidget(
      message: message,
      isError: isError,
      actionLabel: actionLabel,
      onAction: onAction,
      onDismiss: () {
        overlayEntry.remove();
      },
    ),
  );

  overlay.insert(overlayEntry);
}

class _GlassToastWidget extends StatefulWidget {
  const _GlassToastWidget({
    required this.message,
    required this.isError,
    this.actionLabel,
    this.onAction,
    required this.onDismiss,
  });

  final String message;
  final bool isError;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismiss;

  @override
  State<_GlassToastWidget> createState() => _GlassToastWidgetState();
}

class _GlassToastWidgetState extends State<_GlassToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Enter
    _controller.forward();

    // Auto dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onDismiss());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isError ? const Color(0xFFFF5A5F) : const Color(0xFF22C55E);
    final icon = widget.isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final val = Curves.easeOutBack.transform(_controller.value);
            return Transform.translate(
              offset: Offset(0, -100 * (1 - val)),
              child: Opacity(
                opacity: _controller.value.clamp(0.0, 1.0),
                child: child,
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(OBTokens.radiusMD),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: OBTokens.glassWhiteFill,
                  borderRadius: BorderRadius.circular(OBTokens.radiusMD),
                  border: Border.all(
                    color: color.withValues(alpha: 0.5),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(icon, color: color, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          color: OBTokens.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (widget.actionLabel != null && widget.onAction != null)
                      TextButton(
                        onPressed: () {
                          widget.onAction!();
                          _controller.reverse().then((_) => widget.onDismiss());
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: color,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          widget.actionLabel!,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
