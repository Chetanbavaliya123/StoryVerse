import 'dart:io';

void main() {
  final file = File('admin/seed.dart');
  final content = file.readAsStringSync();
  
  final startStr = 'final _demoStories = <Map<String, dynamic>>[';
  final start = content.indexOf(startStr);
  final end = content.indexOf('];', start) + 2;
  final demoStories = content.substring(start, end).replaceFirst('final _demoStories', 'final List<Map<String, dynamic>> rawDemoStories');
  
  final vStart = content.indexOf('const _videos = [');
  final vEnd = content.indexOf('];', vStart) + 2;
  final videos = content.substring(vStart, vEnd);
  
  final funcs = '''
String _thumb(int seed) {
  if (seed > 100) {
    int storyId = seed ~/ 100;
    return 'assets/images/stories/story_\${storyId.toString().padLeft(2, "0")}.jpg';
  }
  return 'assets/images/stories/story_\${seed.toString().padLeft(2, "0")}.jpg';
}

String _banner(int seed) {
  if (seed > 100) {
    int storyId = seed ~/ 100;
    return 'assets/images/stories/story_\${storyId.toString().padLeft(2, "0")}_banner.jpg';
  }
  return 'assets/images/stories/story_\${seed.toString().padLeft(2, "0")}_banner.jpg';
}
''';

  final out = '''import 'package:storyverse/core/models/story_model.dart';
import 'package:storyverse/core/models/episode_model.dart';

$videos
$funcs

$demoStories

final List<StoryModel> demoStoryCatalog = rawDemoStories.map((data) {
  return StoryModel(
    id: data['id'],
    title: data['title'],
    description: data['description'],
    fullDescription: data['fullDescription'] ?? data['description'],
    thumbnailUrl: data['thumbnailUrl'],
    bannerUrl: data['bannerUrl'],
    genreId: data['genreId'],
    categoryId: data['categoryId'],
    language: data['language'],
    tags: List<String>.from(data['tags']),
    author: data['author'],
    status: data['status'],
    episodeCount: data['episodeCount'],
    views: data['views'],
    rating: data['rating'].toDouble(),
    isTrending: data['isTrending'] ?? false,
    isDemo: data['isDemo'] ?? true,
    isPublished: data['isPublished'] ?? true,
    ageCategory: data['ageCategory'] ?? 'all-ages',
    totalDuration: data['totalDuration'],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}).toList();

final Map<String, List<EpisodeModel>> demoEpisodesCatalog = {};

void initializeDemoCatalog() {
  for (var data in rawDemoStories) {
    final storyId = data['id'];
    final episodesList = data['episodes'] as List;
    demoEpisodesCatalog[storyId] = episodesList.map((epData) => EpisodeModel(
      id: epData['id'],
      storyId: storyId,
      episodeNumber: epData['episodeNumber'],
      title: epData['title'],
      description: epData['description'],
      thumbnailUrl: epData['thumbnailUrl'],
      videoUrl: epData['videoUrl'],
      duration: epData['duration'],
      views: epData['views'],
      status: epData['status'],
      isPublished: epData['isPublished'],
      publishedAt: DateTime.now(),
      createdAt: DateTime.now(),
    )).toList();
  }
}
''';
  final dir = Directory('lib/core/data');
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  File('lib/core/data/demo_story_catalog.dart').writeAsStringSync(out);
  print('Generated lib/core/data/demo_story_catalog.dart');
}
