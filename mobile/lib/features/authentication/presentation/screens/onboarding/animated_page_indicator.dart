import 'dart:math';
import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// Custom animated page indicator: active dot stretches into a 28px gradient
/// red pill (animated by page offset), inactive dots are 8px white 25%.
class AnimatedPageIndicator extends StatelessWidget {
  const AnimatedPageIndicator({
    super.key,
    required this.pageCount,
    required this.pageOffset,
  });

  final int pageCount;
  final double pageOffset;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Page ${(pageOffset + 1).round()} of $pageCount',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(pageCount, (index) {
          // Calculate how "active" this dot is (0.0 to 1.0)
          final distance = (pageOffset - index).abs();
          final activity = (1.0 - distance).clamp(0.0, 1.0);

          final width = OBTokens.dotSize +
              (OBTokens.dotActiveWidth - OBTokens.dotSize) * activity;

          return Padding(
            padding: EdgeInsets.only(
              right: index < pageCount - 1 ? OBTokens.dotSpacing : 0,
            ),
            child: Container(
              width: width,
              height: OBTokens.dotSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(OBTokens.dotSize / 2),
                color: Color.lerp(
                  OBTokens.dotInactive,
                  OBTokens.crimsonStart, // solid color fallback for active
                  activity,
                ),
                gradient: activity > 0.05
                    ? LinearGradient(
                        colors: [
                          Color.lerp(OBTokens.dotInactive, OBTokens.crimsonStart, activity)!,
                          Color.lerp(OBTokens.dotInactive, OBTokens.crimsonEnd, activity)!,
                        ],
                      )
                    : null,
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Thin circular progress ring that fills as pages advance (1/3, 2/3, full).
/// Drawn around the CTA button using CustomPainter.
class ProgressRingPainter extends CustomPainter {
  const ProgressRingPainter({
    required this.progress,
    required this.strokeWidth,
  });

  final double progress; // 0.0 to 1.0
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final sw = strokeWidth / 2;
    final r = (h / 2) - sw; // radius of the semi-circles

    // Build a pill-shaped path starting from top-center and going clockwise.
    final pillPath = Path()
      ..moveTo(w / 2, sw)
      ..lineTo(w - h / 2, sw)
      ..arcToPoint(
        Offset(w - h / 2, h - sw),
        radius: Radius.circular(r),
        clockwise: true,
      )
      ..lineTo(h / 2, h - sw)
      ..arcToPoint(
        Offset(h / 2, sw),
        radius: Radius.circular(r),
        clockwise: true,
      )
      ..close();

    // Background ring
    final bgPaint = Paint()
      ..color = OBTokens.glassWhiteSubtle
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
      
    canvas.drawPath(pillPath, bgPaint);

    if (progress <= 0) return;

    // Progress ring with gradient
    final progressPaint = Paint()
      ..shader = const LinearGradient(
        colors: [OBTokens.crimsonStart, OBTokens.crimsonEnd],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final metrics = pillPath.computeMetrics().toList();
    if (metrics.isNotEmpty) {
      final metric = metrics.first;
      final extract = metric.extractPath(0.0, metric.length * progress);
      canvas.drawPath(extract, progressPaint);
    }
  }

  @override
  bool shouldRepaint(ProgressRingPainter old) => progress != old.progress;
}
