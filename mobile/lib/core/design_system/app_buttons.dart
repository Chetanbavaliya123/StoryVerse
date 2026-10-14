import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'tokens.dart';

class PrimaryButton extends StatelessWidget {
  final String? label;
  final String? text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget? icon;
  final double? width;
  final double height;
  final bool enableGlow;

  const PrimaryButton({
    super.key,
    this.label,
    this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 48.0,
    this.enableGlow = true,
  }) : assert(label != null || text != null, 'Either label or text must be provided');

  String get _buttonText => label ?? text ?? '';

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isEnabled = onPressed != null && !isLoading;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(tokens.radiusPill),
        boxShadow: (enableGlow && isEnabled) ? tokens.glowShadow : null,
      ),
      child: ElevatedButton(
        onPressed: isEnabled
            ? () {
                HapticFeedback.lightImpact();
                onPressed!();
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: tokens.accent,
          disabledBackgroundColor: tokens.accent.withValues(alpha: 0.35),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white54,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.radiusPill),
          ),
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: tokens.spaceLg),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    icon!,
                    SizedBox(width: tokens.spaceSm),
                  ],
                  Text(
                    _buttonText,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget? icon;
  final double? width;
  final double height;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 48.0,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isEnabled = onPressed != null && !isLoading;

    return SizedBox(
      width: width,
      height: height,
      child: OutlinedButton(
        onPressed: isEnabled
            ? () {
                HapticFeedback.lightImpact();
                onPressed!();
              }
            : null,
        style: OutlinedButton.styleFrom(
          backgroundColor: tokens.surfaceElevated.withValues(alpha: 0.5),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white38,
          side: BorderSide(
            color: isEnabled ? tokens.border : tokens.border.withValues(alpha: 0.3),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.radiusPill),
          ),
          padding: EdgeInsets.symmetric(horizontal: tokens.spaceLg),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    icon!,
                    SizedBox(width: tokens.spaceSm),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double size;
  final double iconSize;
  final Color? backgroundColor;
  final Color? iconColor;
  final String? tooltip;

  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
    this.size = 44.0,
    this.iconSize = 22.0,
    this.backgroundColor,
    this.iconColor,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isEnabled = onPressed != null && !isLoading;

    Widget button = InkWell(
      onTap: isEnabled
          ? () {
              HapticFeedback.selectionClick();
              onPressed!();
            }
          : null,
      borderRadius: BorderRadius.circular(size / 2),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor ?? tokens.surfaceElevated.withValues(alpha: 0.8),
          shape: BoxShape.circle,
          border: Border.all(
            color: tokens.border.withValues(alpha: 0.7),
            width: 1,
          ),
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: iconSize * 0.8,
                  height: iconSize * 0.8,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Icon(
                  icon,
                  size: iconSize,
                  color: isEnabled
                      ? (iconColor ?? Colors.white)
                      : Colors.white38,
                ),
        ),
      ),
    );

    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }

    return button;
  }
}
