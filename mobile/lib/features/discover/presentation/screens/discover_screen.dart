import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:storyverse/core/theme/app_colors.dart';
import 'package:storyverse/core/widgets/network_image_with_fallback.dart';
import 'package:storyverse/features/story/presentation/providers/story_provider.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  final String? initialGenre;
  final String? initialLanguage;
  final String? initialCategory;

  const DiscoverScreen({
    super.key,
    this.initialGenre,
    this.initialLanguage,
    this.initialCategory,
  });

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  late String? _selectedGenre;
  late String? _selectedLanguage;
  late String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedGenre = widget.initialGenre;
    _selectedLanguage = widget.initialLanguage;
    _selectedCategory = widget.initialCategory;
  }

  @override
  Widget build(BuildContext context) {
    final genresAsync = ref.watch(genresProvider);

    // Instead of raw latest stories, use multi filter.
    // If category is popular, new, trending, the multi filter provider handles it if implemented,
    // actually wait, storiesByMultiFilterProvider doesn't sort by category popular/trending/new, it just filters categoryId!
    // But we need "popular" "trending" "new" logic.
    // Let's use the explicit providers if category is one of those special keywords.

    AsyncValue<List<dynamic>> storiesAsync;

    if (_selectedCategory == 'popular') {
      storiesAsync = ref.watch(popularStoriesProvider);
    } else if (_selectedCategory == 'trending') {
      storiesAsync = ref.watch(trendingStoriesProvider);
    } else if (_selectedCategory == 'new') {
      storiesAsync = ref.watch(latestStoriesProvider);
    } else {
      storiesAsync = ref.watch(
        storiesByMultiFilterProvider({
          'genre': _selectedGenre,
          'language': _selectedLanguage,
          'category': _selectedCategory,
        }),
      );
    }

    String displayTitle = 'Discover';
    if (_selectedCategory == 'popular') {
      displayTitle = 'Popular';
    } else if (_selectedCategory == 'trending')
      displayTitle = 'Trending';
    else if (_selectedCategory == 'new')
      displayTitle = 'New Arrivals';
    else if (_selectedLanguage != null)
      displayTitle = '${_selectedLanguage!.toUpperCase()} Stories';
    else if (_selectedGenre != null)
      displayTitle = _selectedGenre!.toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          displayTitle,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Genre filter chips (Only show if we aren't hard-locked into a language/category that ignores them)
          if (_selectedLanguage == null && _selectedCategory == null)
            SizedBox(
              height: 50,
              child: genresAsync.when(
                data: (genres) {
                  if (genres.isEmpty) return const SizedBox.shrink();
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: genres.length + 1,
                    itemBuilder: (context, index) {
                      final isAll = index == 0;
                      final genre = isAll ? null : genres[index - 1];
                      final isSelected = _selectedGenre == genre;
                      final label = isAll ? 'All' : genre!.toUpperCase();

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(
                            label,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.secondaryText,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (_) =>
                              setState(() => _selectedGenre = genre),
                          backgroundColor: AppColors.primarySurface,
                          selectedColor: AppColors.primaryAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primaryAccent
                                  : AppColors.border,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryAccent,
                  ),
                ),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ),

          if (_selectedLanguage == null && _selectedCategory == null)
            const SizedBox(height: 16),

          // Results
          Expanded(
            child: storiesAsync.when(
              data: (stories) {
                if (stories.isEmpty) {
                  return const Center(
                    child: Text(
                      'No stories found matching your filters',
                      style: TextStyle(color: AppColors.secondaryText),
                    ),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: stories.length,
                  itemBuilder: (context, index) {
                    final story = stories[index];
                    return InkWell(
                      onTap: () => context.push('/story/${story.id}'),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                                child: NetworkImageWithFallback(
                                  imageUrl: story.thumbnailUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    story.genreId.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.primaryAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    story.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        color: Colors.amber,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${story.rating}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.secondaryText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryAccent,
                ),
              ),
              error: (e, st) => const Center(
                child: Text(
                  'Failed to load stories',
                  style: TextStyle(color: AppColors.primaryAccent),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
