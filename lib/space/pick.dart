import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

import 'frame_snapshot.dart';
import 'system.dart';

/// The smallest radius on the screen that a body can be picked within, in
/// logical pixels, for bodies that are only a few pixels across.
const minPickRadius = 14.0;

/// The index in [FrameSnapshot.bodies] of the body at [pixel] of the
/// frame's screen, or null if there is none.
///
/// The ray picks the nearest body it enters using bodies' actual size,
/// or [minPickRadius] as a fallback.
int? pickBody(FrameSnapshot frame, Vector2 pixel) {
  final camera = frame.camera;
  final direction = camera.rayThrough(pixel, frame.screen);
  final holeEntry = _entryDistance(
    camera.position,
    direction,
    Sphere.centerRadius(Vector3.zero(), holeShadowRadius),
  );

  /// The nearest body that the ray enters before the hole, with
  /// each body's sphere given by [sphereOf].
  int? nearestBody(Sphere Function(Sphere body) sphereOf) {
    var nearest = holeEntry;
    int? picked;
    for (final (i, body) in frame.bodies.indexed) {
      final entry = _entryDistance(
        camera.position,
        direction,
        sphereOf(body.sphere),
      );
      if (entry != null && (nearest == null || entry < nearest)) {
        nearest = entry;
        picked = i;
      }
    }
    return picked;
  }

  return nearestBody((body) => body) ??
      nearestBody((body) {
        // A radius of minPickRadius pixels at the body's depth, in world
        // units. It is negative for a body behind the camera, so the body
        // keeps its own radius.
        final depth = (body.center - camera.position).dot(camera.forward);
        final minRadius = minPickRadius * depth / camera.focalLength;
        return Sphere.centerRadius(
          body.center,
          math.max(body.radius, minRadius),
        );
      });
}

/// How far the ray from [origin] along [direction], of length 1, travels
/// before it enters [sphere], or null if it misses the sphere or enters it
/// behind [origin]. The same as `distanceToSphere` in `shaders/scene.frag`.
double? _entryDistance(Vector3 origin, Vector3 direction, Sphere sphere) {
  final toCentre = sphere.center - origin;
  // How far along the ray it comes nearest the sphere's centre.
  final alongToNearest = toCentre.dot(direction);
  // How near it comes, squared, by Pythagoras.
  final nearestSquared = toCentre.length2 - alongToNearest * alongToNearest;
  // Half the chord the ray cuts through the sphere, squared, by Pythagoras
  // again. It is negative if the ray misses the sphere.
  final halfChordSquared = sphere.radius * sphere.radius - nearestSquared;
  if (halfChordSquared < 0) return null;
  final entry = alongToNearest - math.sqrt(halfChordSquared);
  return entry > 0 ? entry : null;
}
