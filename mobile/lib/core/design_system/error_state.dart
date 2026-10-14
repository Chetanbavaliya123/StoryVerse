import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'tokens.dart';
import 'app_buttons.dart';

class ErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;
  final IconData icon;

  const ErrorState({
    super.key,
    this.title = 'Something went wrong',
    required this.message,
    this.onRetry,
    this.retryLabel = 'Try Again',
    this.icon = Icons.error_outline_rounded,
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
                color: tokens.accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: tokens.accent.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(
                icon,
                size: 48,
                color: tokens.accent,
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
            if (onRetry != null) ...[
              SizedBox(height: tokens.spaceXl),
              PrimaryButton(
                label: retryLabel,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onRetry!();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
