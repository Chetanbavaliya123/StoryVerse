import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storyverse/core/theme/app_colors.dart';
import 'package:storyverse/features/search/presentation/providers/search_provider.dart';
import 'package:storyverse/core/models/story_model.dart';
import 'package:storyverse/core/widgets/story_card.dart';
import 'package:storyverse/core/widgets/empty_state.dart';
import 'package:storyverse/core/widgets/skeleton_loader.dart';
import 'package:storyverse/features/search/presentation/widgets/voice_search_dialog.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  final List<String> _popularCategories = const [
    'Romance',
    'Horror',
    'Comedy',
    'Sci-Fi',
    'Action',
    'Hindi',
    'English',
    'Gujarati',
    'Bengali',
    'Marathi',
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(searchQueryProvider));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSelectQuery(String query) {
    _controller.text = query;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: query.length),
    );
    ref.read(searchQueryProvider.notifier).setImmediate(query);
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final resultsAsync = ref.watch(searchStoriesProvider);
    final recentSearches = ref.watch(recentSearchesProvider);

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
                  'EXPLORE',
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
              'Search',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        toolbarHeight: 90,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                boxShadow: _focusNode.hasFocus
                    ? [
                        BoxShadow(
                          color: AppColors.primaryAccent.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Search stories, genres, authors...',
                  hintStyle: const TextStyle(color: AppColors.mutedText),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.secondaryText,
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (query.isNotEmpty)
                        IconButton(
                          icon: const Icon(
                            Icons.clear,
                            color: AppColors.secondaryText,
                          ),
                          onPressed: () {
                            _controller.clear();
                            ref.read(searchQueryProvider.notifier).clear();
                          },
                        ),
                      IconButton(
                        icon: const Icon(
                          Icons.mic_rounded,
                          color: AppColors.primaryAccent,
                        ),
                        tooltip: 'Voice Search',
                        onPressed: () => VoiceSearchDialog.show(context),
                      ),
                    ],
                  ),
                  filled: true,
                  fillColor: AppColors.primarySurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(
                      color: AppColors.primaryAccent,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onChanged: (value) =>
                    ref.read(searchQueryProvider.notifier).update(value),
                onSubmitted: (value) =>
                    ref.read(searchQueryProvider.notifier).setImmediate(value),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: query.isEmpty
                  ? _buildEmptyStateView(recentSearches)
                  : resultsAsync.when(
                      data: (stories) {
                        if (stories.isEmpty) {
                          return const EmptyState(
                            key: ValueKey('no_results'),
                            icon: Icons.search_off_rounded,
                            title: 'No results found',
                            message: 'Try adjusting your search terms.',
                          );
                        }
                        return _buildResultsGrid(stories);
                      },
                      loading: () => _buildLoadingSkeleton(),
                      error: (e, _) => EmptyState(
                        key: const ValueKey('error'),
                        icon: Icons.error_outline,
                        title: 'Error',
                        message: 'Failed to search stories: $e',
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateView(List<String> recentSearches) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      children: [
        if (recentSearches.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Searches',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () =>
                    ref.read(recentSearchesProvider.notifier).clearAll(),
                child: const Text(
                  'Clear All',
                  style: TextStyle(color: AppColors.mutedText, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recentSearches.map((term) {
              return InputChip(
                backgroundColor: AppColors.primarySurface,
                side: const BorderSide(color: AppColors.border),
                label: Text(
                  term,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                onPressed: () => _onSelectQuery(term),
                onDeleted: () =>
                    ref.read(recentSearchesProvider.notifier).remove(term),
                deleteIconColor: AppColors.secondaryText,
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],

        const Text(
          'Popular Categories & Languages',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _popularCategories.map((cat) {
            return ActionChip(
              backgroundColor: AppColors.primarySurface,
              side: BorderSide(
                color: AppColors.primaryAccent.withValues(alpha: 0.35),
              ),
              label: Text(
                cat,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              onPressed: () => _onSelectQuery(cat),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildResultsGrid(List<StoryModel> stories) {
    return GridView.builder(
      key: const ValueKey('results_grid'),
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 120),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: stories.length,
      itemBuilder: (context, index) {
        return StoryCard(
          story: stories[index],
          width: double.infinity,
          height: double.infinity,
        );
      },
    );
  }

  Widget _buildLoadingSkeleton() {
    return GridView.builder(
      key: const ValueKey('loading_skeleton'),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return const SkeletonLoader(
          width: double.infinity,
          height: double.infinity,
          borderRadius: 16,
        );
      },
    );
  }
}
