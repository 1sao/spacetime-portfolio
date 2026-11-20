import 'package:vector_math/vector_math_64.dart';

import 'body.dart';
import 'camera.dart';

/// A single source of truth for everything that moves, at one moment. The
/// frame loop builds one per frame.
///
/// Caution: the vectors of [camera] and the spheres of [bodies] are
/// mutable, and every reader of the frame shares them, so they should not
/// be changed in place.
class FrameSnapshot {
  FrameSnapshot({
    required this.actualTime,
    required this.orbitTime,
    required this.spinTime,
    required this.camera,
    required List<Sphere> bodies,
  }) : bodies = List.unmodifiable(bodies);

  /// The snapshot with [bodies] at their positions at [orbitTime].
  FrameSnapshot.of(
    List<Body> bodies, {
    required double actualTime,
    required double orbitTime,
    required double spinTime,
    required Camera camera,
  }) : this(
         actualTime: actualTime,
         orbitTime: orbitTime,
         spinTime: spinTime,
         camera: camera,
         bodies: [
           for (final body in bodies)
             Sphere.centerRadius(body.positionAt(orbitTime), body.radius),
         ],
       );

  /// The seconds that the frame loop has run: real time, which only goes
  /// forward. It stands still while the scene does.
  final double actualTime;

  /// The clock that moves the bodies along their orbits.
  ///
  /// The visitor sets it, so it can go back, and it does not follow
  /// [actualTime].
  final double orbitTime;

  /// The clock that turns the bodies on their axes. The visitor sets it,
  /// as [orbitTime].
  final double spinTime;

  /// Where the scene is seen from.
  final Camera camera;

  /// Each section's body, in page order, as a sphere: its centre and
  /// radius, in world units.
  final List<Sphere> bodies;
}
