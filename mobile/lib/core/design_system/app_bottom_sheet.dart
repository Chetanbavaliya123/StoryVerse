import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'tokens.dart';

class AppBottomSheet extends StatelessWidget {
  final String? title;
  final Widget? trailing;
  final Widget child;
  final double? maxHeight;
  final EdgeInsetsGeometry padding;

  const AppBottomSheet({
    super.key,
    this.title,
    this.trailing,
    required this.child,
    this.maxHeight,
    this.padding = const EdgeInsets.all(20),
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    Widget? trailing,
    bool isScrollControlled = true,
  }) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (ctx) => AppBottomSheet(
        title: title,
        trailing: trailing,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: maxHeight ?? MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: tokens.surface.withValues(alpha: 0.96),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(tokens.radiusXl),
          ),
          border: Border.all(
            color: tokens.border.withValues(alpha: 0.6),
            width: 1,
          ),
          boxShadow: tokens.softShadow,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Grabber Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 38,
                height: 4.5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),

              // Optional Header
              if (title != null || trailing != null)
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: tokens.spaceLg,
                    vertical: tokens.spaceSm,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (title != null)
                        Expanded(
                          child: Text(
                            title!,
                            style: tokens.sectionHeader.copyWith(fontSize: 19),
                          ),
                        ),
                      ?trailing,
                    ],
                  ),
                ),

              // Divider if header present
              if (title != null || trailing != null)
                Divider(
                  height: 1,
                  color: tokens.border.withValues(alpha: 0.5),
                ),

              // Content
              Padding(
                padding: padding,
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
