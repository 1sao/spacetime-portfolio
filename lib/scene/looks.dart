import 'dart:ui';

/// How the scene is coloured.
class Looks {
  const Looks({required this.hole, required this.bodies});

  /// The colour of the hole at the origin.
  final Color hole;

  /// One colour per body slot, in page order: the first section's body
  /// takes the first colour.
  final List<Color> bodies;
}

const placeholderLooks = Looks(
  hole: Color(0xFFFFD98C),
  bodies: [
    Color(0xFF8CD9FF),
    Color(0xFFFFB3FF),
    Color(0xFFFF9E66),
    Color(0xFF99FFFF),
  ],
);
