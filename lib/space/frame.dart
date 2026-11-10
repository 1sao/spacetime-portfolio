import 'package:vector_math/vector_math_64.dart';

import 'body.dart';
import 'camera.dart';

/// A single source of truth for everything that moves, at one moment. The
/// frame loop builds one per frame.
class FrameSnapshot {
  FrameSnapshot({
    required this.time,
    required this.camera,
    required List<Sphere> bodies,
  }) : bodies = List.unmodifiable(bodies);

  FrameSnapshot.at(double time, Camera camera, List<Body> bodies)
    : this(
        time: time,
        camera: camera,
        bodies: [
          for (final body in bodies)
            Sphere.centerRadius(body.positionAt(time), body.radius),
        ],
      );

  /// The time of the frame, in seconds on the clock of the scene.
  final double time;

  /// Where the scene is seen from.
  final Camera camera;

  /// Each category's body, in content order, as a sphere: its centre and
  /// radius, in world units.
  ///
  /// Caution: spheres are mutable, and every reader of the frame shares
  /// these, so they shouldn't be changed in place.
  final List<Sphere> bodies;
}
