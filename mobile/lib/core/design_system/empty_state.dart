import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'tokens.dart';
import 'app_buttons.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(tokens.spaceLg),
              decoration: BoxDecoration(
                color: tokens.surfaceElevated.withValues(alpha: 0.6),
                shape: BoxShape.circle,
                border: Border.all(
                  color: tokens.border.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                size: 56,
                color: tokens.textMuted.withValues(alpha: 0.7),
              ),
            ),
            SizedBox(height: tokens.spaceLg),
            Text(
              title,
              style: tokens.sectionHeader.copyWith(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: tokens.spaceSm),
            Text(
              message,
              style: tokens.body,
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: tokens.spaceXl),
              PrimaryButton(
                label: actionLabel!,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onAction!();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
