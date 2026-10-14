import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:storyverse/core/theme/app_colors.dart';
import 'package:storyverse/features/library/presentation/providers/library_provider.dart';
import 'package:storyverse/core/widgets/story_card.dart';
import 'package:storyverse/core/widgets/empty_state.dart';
import 'package:storyverse/core/widgets/skeleton_loader.dart';
import 'package:storyverse/features/library/data/library_repository.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  final int? initialTabIndex;
  const LibraryScreen({super.key, this.initialTabIndex});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<String> _hiddenStoryIds = {};
  final Map<String, Timer> _pendingDeletionTimers = {};

  @override
  void initState() {
    super.initState();
    final initialIndex = (widget.initialTabIndex ?? 0).clamp(0, 3);
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: initialIndex,
    );
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    for (final timer in _pendingDeletionTimers.values) {
      timer.cancel();
    }
    _tabController.dispose();
    super.dispose();
  }

  String _formatWatchTimestamp(DateTime? dateTime) {
    if (dateTime == null) return 'Watched recently';
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  void _deleteWithUndo({
    required BuildContext context,
    required String storyId,
    required String storyTitle,
  }) {
    setState(() {
      _hiddenStoryIds.add(storyId);
    });

    _pendingDeletionTimers[storyId]?.cancel();
    _pendingDeletionTimers[storyId] = Timer(const Duration(seconds: 4), () {
      ref.read(libraryRepositoryProvider).removeFromWatchHistory(storyId);
      _pendingDeletionTimers.remove(storyId);
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed "$storyTitle" from history'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Undo',
          textColor: AppColors.primaryAccent,
          onPressed: () {
            _pendingDeletionTimers[storyId]?.cancel();
            _pendingDeletionTimers.remove(storyId);
            setState(() {
              _hiddenStoryIds.remove(storyId);
            });
          },
        ),
      ),
    );
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
                  Tab(text: 'AI Stories'),
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
          _buildAiStoriesTab(),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    final historyAsync = ref.watch(detailedWatchHistoryProvider);

    return historyAsync.when(
      data: (items) {
        final visibleItems = items
            .where((item) => !_hiddenStoryIds.contains(item.story.id))
            .toList();
        if (visibleItems.isEmpty) {
          return const EmptyState(
            icon: Icons.history_rounded,
            title: 'No Watch History',
            message: 'Stories you start watching will appear here.',
          );
        }
        return Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (dialogCtx) => AlertDialog(
                          backgroundColor: AppColors.primarySurface,
                          title: const Text('Clear History',
                              style: TextStyle(color: Colors.white)),
                          content: const Text(
                              'Are you sure you want to clear your entire watch history? This cannot be undone.',
                              style: TextStyle(color: AppColors.secondaryText)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogCtx, false),
                              child: const Text('Cancel',
                                  style: TextStyle(color: Colors.white)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(dialogCtx, true),
                              child: const Text('Clear All',
                                  style: TextStyle(color: Colors.redAccent)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await ref
                            .read(libraryRepositoryProvider)
                            .clearWatchHistory();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Watch history cleared'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.delete_sweep_rounded,
                        color: AppColors.secondaryText, size: 20),
                    label: const Text('Clear History',
                        style: TextStyle(color: AppColors.secondaryText)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                itemCount: visibleItems.length,
                itemBuilder: (context, index) {
                  final item = visibleItems[index];
                  final timeAgo =
                      _formatWatchTimestamp(item.history.lastWatchedAt);
                  final pct = (item.history.percentage * 100).toInt();

                  return StoryCard(
                    story: item.story,
                    isHorizontal: true,
                    subtitle: 'Ep ${item.episode.episodeNumber} • $timeAgo ($pct%)',
                    progress: item.history.percentage,
                    onTap: () => context.push(
                      '/player/${item.story.id}/${item.episode.id}',
                    ),
                    onDelete: () => _deleteWithUndo(
                      context: context,
                      storyId: item.story.id,
                      storyTitle: item.story.title,
                    ),
                  );
                },
              ),
            ),
          ],
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
    final libraryAsync = ref.watch(savedStoriesProvider);

    return libraryAsync.when(
      data: (stories) {
        if (stories.isEmpty) {
          return const EmptyState(
            icon: Icons.bookmark_border_rounded,
            title: 'Your Library is Empty',
            message: 'Save episodes to access them here.',
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
              subtitle: 'Saved to Library',
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

  Widget _buildAiStoriesTab() {
    final aiStoriesAsync = ref.watch(aiStoriesProvider);

    return aiStoriesAsync.when(
      data: (stories) {
        final visibleStories = stories.where((s) => !_hiddenStoryIds.contains(s.id)).toList();
        if (visibleStories.isEmpty) {
          return const EmptyState(
            icon: Icons.auto_awesome,
            title: 'No AI Stories',
            message: 'Generate and save AI stories to see them here.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: visibleStories.length,
          itemBuilder: (context, index) {
            final story = visibleStories[index];
            return StoryCard(
              story: story,
              isHorizontal: true,
              subtitle: 'Generated AI Story',
              onDelete: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppColors.primarySurface,
                    title: const Text('Delete Story', style: TextStyle(color: Colors.white)),
                    content: const Text('Remove this story from your saved stories?', style: TextStyle(color: AppColors.secondaryText)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  setState(() {
                    _hiddenStoryIds.add(story.id);
                  });
                  ref.read(libraryRepositoryProvider).toggleLibrary(story.id, false).then((_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Story removed')));
                    }
                  });
                }
              },
            );
          },
        );
      },
      loading: () => _buildLoadingList(),
      error: (e, _) => EmptyState(
        icon: Icons.error_outline,
        title: 'Error Loading AI Stories',
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
