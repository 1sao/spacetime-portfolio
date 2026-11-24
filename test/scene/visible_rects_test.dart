import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:spacetime_portfolio/scene/visible_rects.dart';

void main() {
  const area = Rect.fromLTWH(0, 0, 100, 80);

  test('Rect.visibleRects is the whole rectangle with no hidden rectangles, or '
      'with hidden rectangles outside it', () {
    expect(area.visibleRects([]), [area]);
    expect(area.visibleRects([const Rect.fromLTWH(200, 0, 10, 10)]), [area]);
  });

  test('Rect.visibleRects is nothing when a hidden rectangle covers it', () {
    expect(area.visibleRects([area.inflate(10)]), isEmpty);
  });

  test('Rect.visibleRects covers the rectangle outside the hidden rectangles, '
      'in parts that do not overlap', () {
    final cases = {
      'one in the middle': (
        hiddenRects: [const Rect.fromLTWH(20, 10, 50, 40)],
        hiddenArea: 50 * 40,
      ),
      'one across the bottom edge': (
        hiddenRects: [const Rect.fromLTWH(10, 60, 80, 40)],
        hiddenArea: 80 * 20,
      ),
      'two that overlap': (
        hiddenRects: [
          const Rect.fromLTWH(10, 10, 40, 40),
          const Rect.fromLTWH(30, 30, 40, 40),
        ],
        hiddenArea: 40 * 40 * 2 - 20 * 20,
      ),
      'two apart': (
        hiddenRects: [
          const Rect.fromLTWH(10, 0, 80, 30),
          const Rect.fromLTWH(10, 50, 80, 30),
        ],
        hiddenArea: 80 * 30 * 2,
      ),
    };
    for (final MapEntry(key: name, value: (:hiddenRects, :hiddenArea))
        in cases.entries) {
      final parts = area.visibleRects(hiddenRects);
      final partsArea = parts.fold(
        0.0,
        (sum, part) => sum + part.width * part.height,
      );
      expect(partsArea, area.width * area.height - hiddenArea, reason: name);
      for (final (i, part) in parts.indexed) {
        for (final other in [...parts.skip(i + 1), ...hiddenRects]) {
          expect(part.intersect(other).isEmpty, isTrue, reason: name);
        }
      }
    }
  });
}
