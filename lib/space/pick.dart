import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

import 'frame_snapshot.dart';
import 'system.dart';

/// In logical pixels, for bodies that are only a few pixels across.
const minPickRadius = 14.0;

/// The index in [FrameSnapshot.bodies] of the body at [pixel]. A body
/// that the ray misses can still be picked within [minPickRadius].
int? pickBody(FrameSnapshot frame, Vector2 pixel) {
  final camera = frame.camera;
  final direction = camera.rayThrough(pixel, frame.screen);
  final holeEntry = _entryDistance(
    camera.position,
    direction,
    Sphere.centerRadius(Vector3.zero(), holeShadowRadius),
  );

  int? nearestBodyBeforeHole(Sphere Function(Sphere body) sphereOf) {
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

  return nearestBodyBeforeHole((body) => body) ??
      nearestBodyBeforeHole((body) {
        // Negative for a body behind the camera, which keeps its own radius.
        final depth = (body.center - camera.position).dot(camera.forward);
        final minRadius = minPickRadius * depth / camera.focalLength;
        return Sphere.centerRadius(
          body.center,
          math.max(body.radius, minRadius),
        );
      });
}

/// [direction] has length 1. Null if the ray misses [sphere] or enters it
/// behind [origin]. The same as `distanceToSphere` in `shaders/scene.frag`.
double? _entryDistance(Vector3 origin, Vector3 direction, Sphere sphere) {
  final toCenter = sphere.center - origin;
  // How far along the ray it comes nearest the sphere's center.
  final alongToNearest = toCenter.dot(direction);
  // How near it comes, squared, by Pythagoras.
  final nearestSquared = toCenter.length2 - alongToNearest * alongToNearest;
  // Half the chord the ray cuts through the sphere, squared, by Pythagoras
  // again. It is negative if the ray misses the sphere.
  final halfChordSquared = sphere.radius * sphere.radius - nearestSquared;
  if (halfChordSquared < 0) return null;
  final entry = alongToNearest - math.sqrt(halfChordSquared);
  return entry > 0 ? entry : null;
}
