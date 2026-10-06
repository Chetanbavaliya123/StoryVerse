import 'package:flutter/material.dart';
import 'package:storyverse/core/theme/design_tokens.dart';

class PremiumSeekBar extends StatelessWidget {
  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onChanged;

  const PremiumSeekBar({
    super.key,
    required this.position,
    required this.duration,
    required this.onChanged,
  });

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          _formatDuration(position),
          style: DesignTokens.bodyStyle.copyWith(
            color: DesignTokens.textPrimary,
            fontSize: 12,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: DesignTokens.primaryAccent,
              inactiveTrackColor: DesignTokens.textPrimary.withValues(alpha: 0.25),
              thumbColor: DesignTokens.primaryAccent,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              trackHeight: 4,
            ),
            child: Slider(
              value: duration.inMilliseconds > 0
                  ? position.inMilliseconds.toDouble().clamp(
                      0,
                      duration.inMilliseconds.toDouble(),
                    )
                  : 0,
              max: duration.inMilliseconds > 0
                  ? duration.inMilliseconds.toDouble()
                  : 1,
              onChanged: (value) => onChanged(Duration(milliseconds: value.toInt())),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          _formatDuration(duration),
          style: DesignTokens.bodyStyle.copyWith(
            color: DesignTokens.textPrimary,
            fontSize: 12,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
