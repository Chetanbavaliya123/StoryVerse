import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../onboarding/design_tokens.dart';

class GradientDivider extends StatelessWidget {
  const GradientDivider({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  OBTokens.glassWhiteBorder,
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: OBTokens.textMuted,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  OBTokens.glassWhiteBorder,
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class GoogleSignInButton extends StatefulWidget {
  const GoogleSignInButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.isLoading) return;
    setState(() => _isPressed = true);
    HapticFeedback.lightImpact();
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.isLoading) return;
    setState(() => _isPressed = false);
    widget.onPressed();
  }

  void _handleTapCancel() {
    if (widget.isLoading) return;
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final scale = _isPressed ? 0.96 : 1.0;

    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(OBTokens.radiusMD),
            color: OBTokens.glassWhiteFill,
            border: Border.all(
              color: OBTokens.glassWhiteBorder,
              width: 1,
            ),
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(OBTokens.textPrimary),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Official Google Colors CustomPainter
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CustomPaint(painter: _GoogleLogoPainter()),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Continue with Google',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: OBTokens.textPrimary,
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

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Simplified Google G drawing using native paths
    // For a production app, an SVG is better, but this avoids adding flutter_svg
    // if we want to keep dependencies low. The prompt allowed CustomPainter.
    final double w = size.width;
    final double h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;

    // Blue section (Right/Bottom)
    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    
    final bluePath = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(w, center.dy)
      ..arcToPoint(Offset(center.dx, h), radius: Radius.circular(radius), clockwise: true)
      ..lineTo(center.dx, center.dy)
      ..close();
    
    // Add the bar part for blue
    bluePath.addRect(Rect.fromLTRB(w * 0.48, h * 0.42, w, h * 0.58));
    
    // Green section (Bottom/Left)
    final greenPaint = Paint()..color = const Color(0xFF34A853);
    final greenPath = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(center.dx, h)
      ..arcToPoint(Offset(0, center.dy), radius: Radius.circular(radius), clockwise: true)
      ..lineTo(center.dx, center.dy)
      ..close();
      
    // Yellow section (Left/Top)
    final yellowPaint = Paint()..color = const Color(0xFFFBBC05);
    final yellowPath = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(0, center.dy)
      ..arcToPoint(Offset(w * 0.3, h * 0.1), radius: Radius.circular(radius), clockwise: true)
      ..lineTo(center.dx, center.dy)
      ..close();
      
    // Red section (Top)
    final redPaint = Paint()..color = const Color(0xFFEA4335);
    final redPath = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(w * 0.3, h * 0.1)
      ..arcToPoint(Offset(w * 0.9, h * 0.3), radius: Radius.circular(radius), clockwise: true)
      ..lineTo(center.dx, center.dy)
      ..close();

    // Draw all
    canvas.drawPath(greenPath, greenPaint);
    canvas.drawPath(yellowPath, yellowPaint);
    canvas.drawPath(redPath, redPaint);
    canvas.drawPath(bluePath, bluePaint);

    // Cut out inner circle
    canvas.drawCircle(center, radius * 0.55, Paint()..blendMode = BlendMode.clear);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
