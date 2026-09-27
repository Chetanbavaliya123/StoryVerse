import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:storyverse/core/theme/app_colors.dart';
import 'package:storyverse/core/widgets/network_image_with_fallback.dart';
import 'package:storyverse/core/models/story_model.dart';
import 'package:storyverse/features/library/presentation/providers/library_provider.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'YOUR COLLECTION',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 2.0,
                    color: AppColors.secondaryText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Library',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        toolbarHeight: 90,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryAccent,
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.secondaryText,
          dividerColor: AppColors.border,
          tabs: const [
            Tab(text: 'History'),
            Tab(text: 'Favorites'),
            Tab(text: 'Downloads'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHistoryTab(),
          _buildFavoritesTab(),
          _buildDownloadsTab(),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    final historyAsync = ref.watch(watchHistoryStoriesProvider);

    return historyAsync.when(
      data: (stories) {
        if (stories.isEmpty) {
          return _buildEmptyState(
            icon: Icons.history,
            title: 'No Watch History',
            message: 'Stories you watch will appear here.',
            actionLabel: 'Discover Stories',
            onAction: () => context.push('/discover'),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: stories.length,
          itemBuilder: (context, index) =>
              _buildStoryItem(stories[index], subtitle: 'Continue Watching'),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryAccent),
      ),
      error: (_, _) => _buildEmptyState(
        icon: Icons.error_outline,
        title: 'Error',
        message: 'Failed to load history.',
      ),
    );
  }

  Widget _buildFavoritesTab() {
    final favoritesAsync = ref.watch(favoriteStoriesProvider);

    return favoritesAsync.when(
      data: (stories) {
        if (stories.isEmpty) {
          return _buildEmptyState(
            icon: Icons.favorite_border,
            title: 'No Favorites Yet',
            message: 'Tap the heart icon on any story to save it here.',
            actionLabel: 'Browse Stories',
            onAction: () => context.push('/discover'),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: stories.length,
          itemBuilder: (context, index) => _buildStoryItem(stories[index]),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryAccent),
      ),
      error: (_, _) => _buildEmptyState(
        icon: Icons.error_outline,
        title: 'Error',
        message: 'Failed to load favorites.',
      ),
    );
  }

  Widget _buildDownloadsTab() {
    final libraryAsync = ref.watch(libraryStoriesProvider);

    return libraryAsync.when(
      data: (stories) {
        if (stories.isEmpty) {
          return _buildEmptyState(
            icon: Icons.download_outlined,
            title: 'No Downloads',
            message: 'Stories saved to your library will appear here.',
            actionLabel: 'Explore Library',
            onAction: () => context.push('/discover'),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: stories.length,
          itemBuilder: (context, index) => _buildStoryItem(stories[index]),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryAccent),
      ),
      error: (_, _) => _buildEmptyState(
        icon: Icons.error_outline,
        title: 'Error',
        message: 'Failed to load library.',
      ),
    );
  }

  Widget _buildStoryItem(StoryModel story, {String? subtitle}) {
    return InkWell(
      onTap: () => context.push('/story/${story.id}'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: NetworkImageWithFallback(
                imageUrl: story.thumbnailUrl,
                width: 100,
                height: 120,
                fit: BoxFit.cover,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      story.genreId.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.primaryAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      story.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle ?? '${story.episodeCount} Episodes',
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Icon(
                Icons.play_circle_outline,
                color: AppColors.primaryAccent,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(icon, size: 48, color: AppColors.secondaryText),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 14,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
