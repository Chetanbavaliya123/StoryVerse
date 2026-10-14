import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:storyverse/core/models/story_model.dart';
import 'tokens.dart';
import 'shimmer_image.dart';

enum StoryCardVariant { poster, hero, compact }

class StoryCard extends StatefulWidget {
  final StoryModel story;
  final StoryCardVariant variant;
  final String? subtitle;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final double? progress;
  final VoidCallback? onDelete;
  final int? rank;
  final bool isHorizontal;

  const StoryCard({
    super.key,
    required this.story,
    this.variant = StoryCardVariant.poster,
    this.subtitle,
    this.onTap,
    this.width,
    this.height,
    this.progress,
    this.onDelete,
    this.rank,
    this.isHorizontal = false,
  });

  const StoryCard.poster({
    super.key,
    required this.story,
    this.subtitle,
    this.onTap,
    this.width = 140,
    this.height = 200,
    this.rank,
  })  : variant = StoryCardVariant.poster,
        progress = null,
        onDelete = null,
        isHorizontal = false;

  const StoryCard.hero({
    super.key,
    required this.story,
    this.subtitle,
    this.onTap,
    this.width = double.infinity,
    this.height = 260,
  })  : variant = StoryCardVariant.hero,
        progress = null,
        onDelete = null,
        rank = null,
        isHorizontal = false;

  const StoryCard.compact({
    super.key,
    required this.story,
    this.subtitle,
    this.onTap,
    this.progress,
    this.onDelete,
    this.width = double.infinity,
    this.height = 110,
  })  : variant = StoryCardVariant.compact,
        rank = null,
        isHorizontal = true;

  @override
  State<StoryCard> createState() => _StoryCardState();
}

class _StoryCardState extends State<StoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    if (widget.onTap != null) {
      widget.onTap!();
    } else {
      context.push('/story/${widget.story.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isHorizontal || widget.variant == StoryCardVariant.compact) {
      return _buildCompact(context);
    }
    switch (widget.variant) {
      case StoryCardVariant.poster:
        return _buildPoster(context);
      case StoryCardVariant.hero:
        return _buildHero(context);
      case StoryCardVariant.compact:
        return _buildCompact(context);
    }
  }

  Widget _buildPoster(BuildContext context) {
    final tokens = context.tokens;
    final w = widget.width ?? 140.0;
    final h = widget.height;
    final isFullWidth = (w == double.infinity);

    // If explicit finite height is provided, use it. Otherwise, if not full-width, default to 215.0
    final double? cardHeight = (h != null && h.isFinite)
        ? h
        : (isFullWidth ? null : 215.0);

    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) => _scaleController.reverse(),
      onTapCancel: () => _scaleController.reverse(),
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: w,
          height: cardHeight,
          margin: isFullWidth
              ? EdgeInsets.zero
              : const EdgeInsets.only(right: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: tokens.surfaceElevated,
                    borderRadius: BorderRadius.circular(tokens.radiusMd),
                    border: Border.all(
                      color: tokens.border.withValues(alpha: 0.7),
                      width: 1,
                    ),
                    boxShadow: tokens.softShadow,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(tokens.radiusMd - 1),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Hero(
                          tag: 'story_poster_${widget.story.id}',
                          child: ShimmerImage(
                            imageUrl: widget.story.thumbnailUrl,
                            title: widget.story.title,
                            genre: widget.story.genreId,
                            fit: BoxFit.cover,
                          ),
                        ),
                        // Rank Badge if Top 10
                        if (widget.rank != null)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: tokens.accent,
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: tokens.glowShadow,
                              ),
                              child: Text(
                                '#${widget.rank}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        // Gradient overlay at bottom
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: 70,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.85),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Bottom metadata on image
                        Positioned(
                          bottom: 8,
                          left: 8,
                          right: 8,
                          child: Text(
                            widget.story.genreId.toUpperCase(),
                            style: TextStyle(
                              color: tokens.accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.story.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                widget.subtitle ?? '${widget.story.episodeCount} Episodes',
                style: TextStyle(
                  color: tokens.textMuted,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    final tokens = context.tokens;
    final h = widget.height ?? 260.0;

    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) => _scaleController.reverse(),
      onTapCancel: () => _scaleController.reverse(),
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          height: h,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: tokens.surfaceElevated,
            borderRadius: BorderRadius.circular(tokens.radiusLg),
            border: Border.all(
              color: tokens.border.withValues(alpha: 0.8),
              width: 1,
            ),
            boxShadow: tokens.softShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(tokens.radiusLg - 1),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Hero(
                  tag: 'story_hero_${widget.story.id}',
                  child: ShimmerImage(
                    imageUrl: widget.story.thumbnailUrl,
                    title: widget.story.title,
                    genre: widget.story.genreId,
                    fit: BoxFit.cover,
                  ),
                ),
                // Cinematic Vignette
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.3),
                        Colors.black.withValues(alpha: 0.95),
                      ],
                      stops: const [0.3, 0.6, 1.0],
                    ),
                  ),
                ),
                // Content Overlay
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: tokens.accent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.story.genreId.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.story.language.toUpperCase(),
                            style: TextStyle(
                              color: tokens.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${widget.story.episodeCount} EPISODES',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.story.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.story.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.story.description,
                          style: TextStyle(
                            color: tokens.textMuted,
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    final tokens = context.tokens;
    final h = widget.height ?? 110.0;

    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) => _scaleController.reverse(),
      onTapCancel: () => _scaleController.reverse(),
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          height: h,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: tokens.surfaceElevated,
            borderRadius: BorderRadius.circular(tokens.radiusMd),
            border: Border.all(
              color: tokens.border.withValues(alpha: 0.6),
              width: 1,
            ),
            boxShadow: tokens.softShadow,
          ),
          child: Row(
            children: [
              // Thumbnail
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(tokens.radiusMd - 1),
                      bottomLeft: Radius.circular(tokens.radiusMd - 1),
                    ),
                    child: ShimmerImage(
                      imageUrl: widget.story.thumbnailUrl,
                      title: widget.story.title,
                      genre: widget.story.genreId,
                      width: 95,
                      height: h,
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (widget.progress != null && widget.progress! > 0)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        value: widget.progress!.clamp(0.0, 1.0),
                        backgroundColor: Colors.black54,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          tokens.accent,
                        ),
                        minHeight: 4,
                      ),
                    ),
                ],
              ),
              // Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.story.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.story.genreId.toUpperCase()} • ${widget.story.language}',
                        style: TextStyle(
                          color: tokens.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.subtitle ?? '${widget.story.episodeCount} Episodes',
                        style: TextStyle(
                          color: tokens.textMuted,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              // Trailing action
              if (widget.onDelete != null)
                IconButton(
                  padding: const EdgeInsets.only(right: 12),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                    size: 24,
                  ),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    widget.onDelete!();
                  },
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Icon(
                    Icons.play_circle_fill_rounded,
                    color: tokens.accent,
                    size: 32,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
