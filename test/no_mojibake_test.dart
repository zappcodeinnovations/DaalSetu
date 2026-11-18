import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards against text saved with the wrong encoding, e.g. the Rupee sign showing up as
/// "â‚¹" (UTF-8 bytes read as Windows-1252) on the product cards.
void main() {
  test('no Dart source contains UTF-8 text decoded with the wrong encoding', () {
    // "â" or "Ã" / "Â" followed by a character that only appears in such garbled text.
    final garbled = RegExp('[ÂÃâ][\u0080-¿ŒœŠšŸŽž'
        'ƒˆ˜–—‘’‚“”„†‡•…‰'
        '‹›€™]');
    final offenders = <String>[];
    for (final file in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (garbled.hasMatch(lines[i])) offenders.add('${file.path}:${i + 1}');
      }
    }
    expect(offenders, isEmpty, reason: 'Fix the encoding (use the real character):\n${offenders.join('\n')}');
  });
}
