import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) {
    print('Please provide the path to the JSON file.');
    return;
  }

  final file = File(args[0]);
  final content = file.readAsStringSync();
  final data = json.decode(content);

  final screens = data['screens'] as List;
  for (var screen in screens) {
    print('Screen ID: ${screen['name']}');
    print('Title: ${screen['title']}');
    print('---');
  }
}
