import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:storyverse/core/theme/app_colors.dart';
import 'package:storyverse/core/widgets/network_image_with_fallback.dart';
import 'package:storyverse/features/search/presentation/providers/search_provider.dart';
import 'package:storyverse/core/models/story_model.dart';

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);
    final resultsAsync = ref.watch(searchStoriesProvider);

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
                  width: 8, height: 8,
                  decoration: const BoxDecoration(color: AppColors.primaryAccent, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                const Text('EXPLORE', style: TextStyle(fontSize: 10, letterSpacing: 2.0, color: AppColors.secondaryText, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            const Text('Search', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        toolbarHeight: 90,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search stories, genres, authors...',
                hintStyle: const TextStyle(color: AppColors.mutedText),
                prefixIcon: const Icon(Icons.search, color: AppColors.secondaryText),
                suffixIcon: query.isNotEmpty 
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.secondaryText),
                        onPressed: () => ref.read(searchQueryProvider.notifier).clear(),
                      )
                    : null,
                filled: true,
                fillColor: AppColors.primarySurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.primaryAccent),
                ),
              ),
              onChanged: (value) => ref.read(searchQueryProvider.notifier).update(value),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: query.isEmpty
                ? _buildEmptyState()
                : resultsAsync.when(
                    data: (stories) => _buildResultsList(stories, context),
                    loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryAccent)),
                    error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 64, color: AppColors.border),
          const SizedBox(height: 16),
          const Text('Find Your Next Story', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Search by title, genre, author, or keywords.', style: TextStyle(color: AppColors.secondaryText, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildResultsList(List<StoryModel> stories, BuildContext context) {
    if (stories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sentiment_dissatisfied, size: 48, color: AppColors.border),
            const SizedBox(height: 16),
            const Text('No Results Found', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: stories.length,
      itemBuilder: (context, index) {
        final story = stories[index];
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
                    height: 140,
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
                          style: const TextStyle(color: AppColors.primaryAccent, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          story.title,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          story.description,
                          style: const TextStyle(color: AppColors.secondaryText, fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 14),
                            const SizedBox(width: 4),
                            Text('${story.rating}', style: const TextStyle(color: AppColors.secondaryText, fontSize: 12)),
                            const SizedBox(width: 12),
                            const Icon(Icons.video_library, color: AppColors.secondaryText, size: 14),
                            const SizedBox(width: 4),
                            Text('${story.episodeCount} ep', style: const TextStyle(color: AppColors.secondaryText, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
