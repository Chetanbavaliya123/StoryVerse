import 'package:flutter/material.dart';
import 'package:storyverse/core/theme/design_tokens.dart';

class NowPlayingIndicator extends StatefulWidget {
  const NowPlayingIndicator({super.key});

  @override
  State<NowPlayingIndicator> createState() => _NowPlayingIndicatorState();
}

class _NowPlayingIndicatorState extends State<NowPlayingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildBar(0),
        const SizedBox(width: 3),
        _buildBar(0.4),
        const SizedBox(width: 3),
        _buildBar(0.8),
      ],
    );
  }

  Widget _buildBar(double delay) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = (_controller.value + delay) % 1.0;
        final height = 6.0 + (12.0 * (value > 0.5 ? 1.0 - value : value) * 2);
        return Container(
          width: 4,
          height: height,
          decoration: BoxDecoration(
            color: DesignTokens.primaryAccent,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      },
    );
  }
}
