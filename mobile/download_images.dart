import 'dart:io';
import 'dart:async';

void main() async {
  final Directory dir = Directory('assets/images/stories');
  final Directory bannerDir = Directory('assets/images/stories/banners');

  if (!dir.existsSync()) dir.createSync(recursive: true);
  if (!bannerDir.existsSync()) bannerDir.createSync(recursive: true);

  final List<String> prompts = [
    'fox in a beautiful forest',
    'lion and a small mouse in the jungle',
    'tortoise and rabbit running a race',
    'black crow and a water pot',
    'goose and a shiny golden egg',
    'honest woodcutter in forest with axe',
    'shepherd boy with sheep and a wolf',
    'ant and a grasshopper in a field',
    'dog with food looking at reflection in water',
    'fox looking up at grapes on a vine',
    'three little pigs standing near their houses',
    'ugly duckling swimming in a lake',
    'little red hen on a sunny farm',
    'fisherman by the stormy sea',
    'vain emperor in a royal setting',
    'magical arabian fantasy environment',
    'brave sailor on a ship in the ocean',
    'clever farmer in a village farm',
    'wise old man sitting in a village',
    'glowing magical tree at night',
    'brave little sparrow flying in sky over forest',
    'ancient kingdom ruins in the mountains',
    'mysterious enchanted forest',
    'fantasy village with seven bells',
    'glowing lantern in a night village',
  ];

  print('Starting parallel downloads...');

  List<Future<void>> tasks = [];

  for (int i = 0; i < prompts.length; i++) {
    int id = i + 1;
    String idStr = id.toString().padLeft(2, '0');
    String prompt = Uri.encodeComponent(
      '${prompts[i]}, high quality, digital art',
    );

    // Thumbnail
    tasks.add(
      _downloadImage(
        'https://image.pollinations.ai/prompt/$prompt?width=400&height=600&nologo=true',
        'assets/images/stories/story_$idStr.webp',
      ),
    );

    // Banner
    tasks.add(
      _downloadImage(
        'https://image.pollinations.ai/prompt/$prompt?width=800&height=400&nologo=true',
        'assets/images/stories/banners/banner_$idStr.webp',
      ),
    );
  }

  await Future.wait(tasks);
  print('All images downloaded successfully.');
}

Future<void> _downloadImage(String url, String path) async {
  try {
    final request = await HttpClient().getUrl(Uri.parse(url));
    final response = await request.close();
    if (response.statusCode == 200) {
      final file = File(path);
      await response.pipe(file.openWrite());
      print('Downloaded: $path');
    } else {
      print('Failed to download $path: \${response.statusCode}');
    }
  } catch (e) {
    print('Error downloading $path: $e');
  }
}
