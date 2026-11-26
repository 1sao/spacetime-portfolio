import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Wider lines are hard to read in a terminal and in a side-by-side diff.
const _maxLineLength = 80;

void main() {
  final docs = [
    File('README.md'),
    File('CLAUDE.md'),
    ...Directory('docs').listSync(recursive: true).whereType<File>(),
    ...Directory('lib').listSync(recursive: true).whereType<File>(),
  ].where((file) => file.path.endsWith('.md'));

  for (final doc in docs) {
    test('${doc.path} has no line longer than $_maxLineLength characters, '
        'apart from a link or a table row', () {
      final longLines = [
        for (final (index, line) in doc.readAsLinesSync().indexed)
          if (line.length > _maxLineLength &&
              !line.contains('://') &&
              !line.trimLeft().startsWith('|'))
            'line ${index + 1}: ${line.length} characters',
      ];
      expect(longLines, isEmpty);
    });
  }
}
