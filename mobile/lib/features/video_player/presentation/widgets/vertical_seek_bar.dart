import 'package:flutter/material.dart';
import 'package:storyverse/core/theme/design_tokens.dart';

class VerticalSeekBar extends StatefulWidget {
  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onSeek;
  final VoidCallback? onSeekStart;
  final VoidCallback? onSeekEnd;

  const VerticalSeekBar({
    super.key,
    required this.position,
    required this.duration,
    required this.onSeek,
    this.onSeekStart,
    this.onSeekEnd,
  });

  @override
  State<VerticalSeekBar> createState() => _VerticalSeekBarState();
}

class _VerticalSeekBarState extends State<VerticalSeekBar> {
  double? _dragValue;
  bool _isDragging = false;

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60);
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final currentPos = _isDragging && _dragValue != null
        ? Duration(milliseconds: _dragValue!.toInt())
        : widget.position;
    final duration = widget.duration;
    final maxMs = duration.inMilliseconds.toDouble();
    final valueMs = maxMs > 0
        ? currentPos.inMilliseconds.toDouble().clamp(0.0, maxMs)
        : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              _formatDuration(currentPos),
              style: DesignTokens.bodyStyle.copyWith(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3.5,
                  activeTrackColor: DesignTokens.primaryAccent,
                  inactiveTrackColor: Colors.white.withValues(alpha: 0.25),
                  thumbColor: DesignTokens.primaryAccent,
                  thumbShape: RoundSliderThumbShape(
                    enabledThumbRadius: _isDragging ? 7.0 : 4.5,
                  ),
                  overlayColor: DesignTokens.primaryAccent.withValues(alpha: 0.2),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                ),
                child: Slider(
                  value: valueMs,
                  min: 0.0,
                  max: maxMs > 0 ? maxMs : 1.0,
                  onChangeStart: (val) {
                    setState(() {
                      _isDragging = true;
                      _dragValue = val;
                    });
                    widget.onSeekStart?.call();
                  },
                  onChanged: (val) {
                    setState(() {
                      _dragValue = val;
                    });
                  },
                  onChangeEnd: (val) {
                    final target = Duration(milliseconds: val.toInt());
                    setState(() {
                      _isDragging = false;
                      _dragValue = null;
                    });
                    widget.onSeek(target);
                    widget.onSeekEnd?.call();
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatDuration(duration),
              style: DesignTokens.bodyStyle.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 11,
                fontWeight: FontWeight.w500,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
