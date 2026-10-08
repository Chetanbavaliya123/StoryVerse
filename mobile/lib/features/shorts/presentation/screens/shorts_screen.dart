import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:storyverse/core/theme/app_colors.dart';
import 'package:storyverse/core/models/story_model.dart';
import 'package:storyverse/core/widgets/network_image_with_fallback.dart';
import 'package:storyverse/features/story/presentation/providers/story_provider.dart';
import 'package:storyverse/features/library/presentation/providers/library_provider.dart';
import 'package:storyverse/features/library/data/library_repository.dart';

class ShortsScreen extends ConsumerStatefulWidget {
  const ShortsScreen({super.key});

  @override
  ConsumerState<ShortsScreen> createState() => _ShortsScreenState();
}

class _ShortsScreenState extends ConsumerState<ShortsScreen> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storiesAsync = ref.watch(trendingStoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      extendBodyBehindAppBar: true,
      body: storiesAsync.when(
        data: (stories) {
          if (stories.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.video_library_outlined,
                    color: AppColors.secondaryText,
                    size: 64,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No Shorts Available',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Short stories will appear here soon.',
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          return PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: stories.length,
            itemBuilder: (context, index) {
              return _ShortStoryCard(
                story: stories[index],
                index: index,
                total: stories.length,
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryAccent),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                e.toString(),
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShortStoryCard extends ConsumerStatefulWidget {
  final StoryModel story;
  final int index;
  final int total;

  const _ShortStoryCard({
    required this.story,
    required this.index,
    required this.total,
  });

  @override
  ConsumerState<_ShortStoryCard> createState() => _ShortStoryCardState();
}

class _ShortStoryCardState extends ConsumerState<_ShortStoryCard> {
  bool _isLiked = false;

  @override
  Widget build(BuildContext context) {
    final isFavoriteAsync = ref.watch(isFavoriteProvider(widget.story.id));
    final isFavorite = isFavoriteAsync.value ?? false;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image
        NetworkImageWithFallback(
          imageUrl: widget.story.bannerUrl ?? widget.story.thumbnailUrl,
          fit: BoxFit.cover,
        ),

        // Dark gradient overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.3),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.8),
              ],
              stops: const [0.0, 0.4, 1.0],
            ),
          ),
        ),

        // Right side actions
        Positioned(
          right: 16,
          bottom: 24,
          child: Column(
            children: [
              _ActionButton(
                icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                label: 'Like',
                color: _isLiked ? Colors.red : Colors.white,
                onTap: () {
                  setState(() {
                    _isLiked = !_isLiked;
                  });
                },
              ),
              const SizedBox(height: 20),
              _ActionButton(
                icon: isFavorite ? Icons.bookmark : Icons.bookmark_border,
                label: 'Save',
                color: isFavorite ? AppColors.primaryAccent : Colors.white,
                onTap: () async {
                  await ref
                      .read(libraryRepositoryProvider)
                      .toggleFavorite(widget.story.id, !isFavorite);
                  ref.invalidate(favoriteStoriesProvider);
                },
              ),
              const SizedBox(height: 20),
              _ActionButton(
                icon: Icons.share_outlined,
                label: 'Share',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Share coming soon!')),
                  );
                },
              ),
              const SizedBox(height: 20),
              _ActionButton(
                icon: Icons.info_outline,
                label: 'Details',
                onTap: () => context.push('/story/${widget.story.id}'),
              ),
            ],
          ),
        ),

        // Bottom info
        Positioned(
          left: 16,
          right: 80,
          bottom: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.story.genreId.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.story.language,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.story.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                widget.story.description,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => context.push('/story/${widget.story.id}'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_arrow, color: Colors.black, size: 20),
                      SizedBox(width: 6),
                      Text(
                        'Watch Now',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.color = Colors.white,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
