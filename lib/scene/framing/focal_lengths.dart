import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../space/camera/camera.dart';
import '../../viewport/window_size.dart';
import 'scene_screen.dart';

final focalLengthsProvider = Provider<FocalLengths>(
  (ref) => FocalLengths.of(ref.watch(sceneScreenProvider)),
);

/// The focal lengths of the scene's framings on a screen.
class FocalLengths {
  factory FocalLengths.of(Screen screen) {
    final isVertical =
        WidthClass.of(screen.width).landingNavigationOrientation ==
        LandingNavigationOrientation.vertical;
    final lineFractionOfWidth = isVertical ? 0.8 : 0.84;
    final sections = math.min(
      screen.width * lineFractionOfWidth / _lineLengthPerFocalLength,
      screen.height * 1.9,
    );
    return FocalLengths._(
      landing: isVertical
          ? math.min(screen.height * 0.56, screen.width * 1.6)
          : sections,
      sections: sections,
    );
  }

  const FocalLengths._({required this.landing, required this.sections});

  final double landing;
  final double sections;

  /// The shortest, so that every sky cell gets a pixel in every framing,
  /// and the sky is not baked again between framings.
  double get sky => math.min(landing, sections);
}

const _lineLengthPerFocalLength = 0.8;
