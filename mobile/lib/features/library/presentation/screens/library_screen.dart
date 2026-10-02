import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storyverse/core/theme/app_colors.dart';
import 'package:storyverse/features/library/presentation/providers/library_provider.dart';
import 'package:storyverse/core/widgets/story_card.dart';
import 'package:storyverse/core/widgets/empty_state.dart';
import 'package:storyverse/core/widgets/skeleton_loader.dart';

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
    _tabController.addListener(() {
      setState(() {});
    });
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(22),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: AppColors.primaryAccent,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.secondaryText,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                dividerColor: Colors.transparent,
                splashBorderRadius: BorderRadius.circular(22),
                tabs: const [
                  Tab(text: 'Watching'),
                  Tab(text: 'Favorites'),
                  Tab(text: 'Saved'),
                ],
              ),
            ),
          ),
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
          return const EmptyState(
            icon: Icons.history_rounded,
            title: 'No Watch History',
            message: 'Stories you start watching will appear here.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: stories.length,
          itemBuilder: (context, index) {
            final story = stories[index];
            return StoryCard(
              story: story,
              isHorizontal: true,
              subtitle: 'Last watched recently',
            );
          },
        );
      },
      loading: () => _buildLoadingList(),
      error: (e, _) => EmptyState(
        icon: Icons.error_outline,
        title: 'Error Loading History',
        message: e.toString(),
      ),
    );
  }

  Widget _buildFavoritesTab() {
    final favoritesAsync = ref.watch(favoriteStoriesProvider);

    return favoritesAsync.when(
      data: (stories) {
        if (stories.isEmpty) {
          return const EmptyState(
            icon: Icons.favorite_border_rounded,
            title: 'No Favorites Yet',
            message: 'Tap the heart icon on any story to save it here.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: stories.length,
          itemBuilder: (context, index) {
            final story = stories[index];
            return StoryCard(story: story, isHorizontal: true);
          },
        );
      },
      loading: () => _buildLoadingList(),
      error: (e, _) => EmptyState(
        icon: Icons.error_outline,
        title: 'Error Loading Favorites',
        message: e.toString(),
      ),
    );
  }

  Widget _buildDownloadsTab() {
    final libraryAsync = ref.watch(libraryStoriesProvider);

    return libraryAsync.when(
      data: (stories) {
        if (stories.isEmpty) {
          return const EmptyState(
            icon: Icons.bookmark_border_rounded,
            title: 'Your Library is Empty',
            message:
                'Save AI generated stories or download episodes to access them here.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: stories.length,
          itemBuilder: (context, index) {
            final story = stories[index];
            return StoryCard(
              story: story,
              isHorizontal: true,
              subtitle: story.categoryId == 'ai-generated'
                  ? 'Generated AI Story'
                  : 'Saved to Library',
            );
          },
        );
      },
      loading: () => _buildLoadingList(),
      error: (e, _) => EmptyState(
        icon: Icons.error_outline,
        title: 'Error Loading Library',
        message: e.toString(),
      ),
    );
  }

  Widget _buildLoadingList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: 5,
      itemBuilder: (context, index) {
        return const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: SkeletonLoader(height: 120, borderRadius: 16),
        );
      },
    );
  }
}
