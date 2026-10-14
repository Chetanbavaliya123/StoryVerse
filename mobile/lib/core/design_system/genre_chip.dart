import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'tokens.dart';

class GenreChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  const GenreChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: isSelected
            ? tokens.accent
            : tokens.surfaceElevated.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(tokens.radiusPill),
        border: Border.all(
          color: isSelected
              ? tokens.accent
              : tokens.border.withValues(alpha: 0.7),
          width: 1.2,
        ),
        boxShadow: isSelected ? tokens.glowShadow : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(tokens.radiusPill),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.spaceMd,
              vertical: tokens.spaceSm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 16,
                    color: isSelected ? Colors.white : tokens.textMuted,
                  ),
                  SizedBox(width: tokens.spaceXs + 2),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : tokens.textMuted,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
