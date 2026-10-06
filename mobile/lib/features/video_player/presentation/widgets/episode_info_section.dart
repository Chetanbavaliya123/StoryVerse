import 'package:flutter/material.dart';
import 'package:storyverse/core/theme/design_tokens.dart';
import 'package:storyverse/core/models/episode_model.dart';
import 'package:flutter_animate/flutter_animate.dart';

class EpisodeInfoSection extends StatefulWidget {
  final EpisodeModel episode;
  final Duration? duration;

  const EpisodeInfoSection({
    super.key,
    required this.episode,
    this.duration,
  });

  @override
  State<EpisodeInfoSection> createState() => _EpisodeInfoSectionState();
}

class _EpisodeInfoSectionState extends State<EpisodeInfoSection> {
  bool _isExpanded = false;

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final durString = widget.duration != null && widget.duration!.inSeconds > 0
        ? _formatDuration(widget.duration!)
        : (widget.episode.duration > 0
            ? widget.episode.formattedDuration
            : 'Duration unavailable');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Episode Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: DesignTokens.primaryAccent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
            border: Border.all(
                color: DesignTokens.primaryAccent.withValues(alpha: 0.3)),
          ),
          child: Text(
            'EPISODE ${widget.episode.episodeNumber}',
            style: DesignTokens.labelStyle,
          ),
        ).animate().fade().slideY(begin: 0.2, end: 0, duration: 400.ms),
        const SizedBox(height: 12),
        // Title
        Text(
          widget.episode.title,
          style: DesignTokens.titleStyle,
        ).animate().fade(delay: 100.ms).slideY(begin: 0.2, end: 0, duration: 400.ms),
        const SizedBox(height: 12),
        // Meta Row
        Row(
          children: [
            const Icon(Icons.access_time_rounded,
                size: 16, color: DesignTokens.textMuted),
            const SizedBox(width: 6),
            Text(
              durString,
              style: DesignTokens.bodyStyle.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ).animate().fade(delay: 200.ms).slideY(begin: 0.2, end: 0, duration: 400.ms),
        const SizedBox(height: 24),
        // Description
        Row(
          children: [
            Container(
              width: 3,
              height: 18,
              decoration: BoxDecoration(
                color: DesignTokens.primaryAccent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Description',
              style: DesignTokens.sectionHeadingStyle,
            ),
          ],
        ).animate().fade(delay: 300.ms),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.episode.description,
                  style: DesignTokens.bodyStyle,
                  maxLines: _isExpanded ? null : 3,
                  overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                ),
                if (widget.episode.description.length > 100) ...[
                  const SizedBox(height: 4),
                  Text(
                    _isExpanded ? 'Show less' : 'Read more',
                    style: DesignTokens.bodyStyle.copyWith(
                      color: DesignTokens.primaryAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ]
              ],
            ),
          ),
        ).animate().fade(delay: 400.ms),
      ],
    );
  }
}
