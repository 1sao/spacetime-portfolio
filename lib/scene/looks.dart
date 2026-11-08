import 'dart:ui';

/// How the scene is coloured.
class Looks {
  const Looks({required this.centralBody, required this.bodies});

  /// The colour of the central body, which every category's body orbits.
  final Color centralBody;

  /// One colour per body slot, in content order: the first category's body
  /// takes the first colour.
  final List<Color> bodies;
}

const placeholderLooks = Looks(
  centralBody: Color(0xFFFFD98C),
  bodies: [
    Color(0xFF8CD9FF),
    Color(0xFFFFB3FF),
    Color(0xFFFF9E66),
    Color(0xFF99FFFF),
  ],
);
