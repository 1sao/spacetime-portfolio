import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:spacetime_portfolio/scene/softness.dart';

void main() {
  test('Rect.offset is the rectangle itself on the sharp scene', () {
    const rect = Rect.fromLTWH(16, 300, 860, 2000);
    expect(rect.offset(SceneSoftness.sharp), rect);
  });

  test('Rect.offset on a soft scene is the rectangle scaled, moved by the '
      'border and smaller by the border on each side', () {
    const softness = SceneSoftness(scale: 0.5, blur: 1);
    expect(softness.border, 4);
    // Scaled: 20, 200, 400 x 600. Moved: 24, 204. Smaller: 28, 208,
    // 392 x 592.
    expect(
      const Rect.fromLTWH(40, 400, 800, 1200).offset(softness),
      const Rect.fromLTWH(28, 208, 392, 592),
    );
  });
}
