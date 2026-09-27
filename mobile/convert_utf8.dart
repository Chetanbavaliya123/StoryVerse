import 'dart:io';

void main() {
  final dir = Directory('lib');
  int convertedCount = 0;
  
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final bytes = entity.readAsBytesSync();
      // Check for UTF-16 LE BOM
      if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE) {
        print('Converting ${entity.path} from UTF-16 LE to UTF-8');
        // Simple ASCII extraction from UTF-16 LE
        final List<int> utf8Bytes = [];
        for (int i = 2; i < bytes.length; i += 2) {
          utf8Bytes.add(bytes[i]);
        }
        entity.writeAsBytesSync(utf8Bytes);
        convertedCount++;
      } else if (bytes.length >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF) {
        print('Converting ${entity.path} from UTF-16 BE to UTF-8');
        // Simple ASCII extraction from UTF-16 BE
        final List<int> utf8Bytes = [];
        for (int i = 2; i < bytes.length; i += 2) {
          utf8Bytes.add(bytes[i+1]);
        }
        entity.writeAsBytesSync(utf8Bytes);
        convertedCount++;
      } else {
        // Just in case it's a UTF-16 file without BOM (which happens)
        // If every other byte is 0, it's likely UTF-16 LE
        int zeroCount = 0;
        for (int i = 1; i < bytes.length && i < 40; i += 2) {
          if (bytes[i] == 0) zeroCount++;
        }
        if (zeroCount > 10) {
          print('Converting ${entity.path} from UTF-16 LE (no BOM) to UTF-8');
          final List<int> utf8Bytes = [];
          for (int i = 0; i < bytes.length; i += 2) {
            utf8Bytes.add(bytes[i]);
          }
          entity.writeAsBytesSync(utf8Bytes);
          convertedCount++;
        }
      }
    }
  }
  print('Converted $convertedCount files.');
}
