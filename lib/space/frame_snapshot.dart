import 'body.dart';
import 'camera.dart';

/// Everything that moves, at one moment. Every reader of the frame shares
/// its mutable vectors, so nothing changes them in place.
class FrameSnapshot {
  FrameSnapshot({
    required this.actualTime,
    required this.orbitTime,
    required this.spinTime,
    required this.screen,
    required this.camera,
    required List<BodyPose> bodies,
  }) : bodies = List.unmodifiable(bodies);

  FrameSnapshot.of(
    List<Body> bodies, {
    required double actualTime,
    required double orbitTime,
    required double spinTime,
    required Screen screen,
    required Camera camera,
  }) : this(
         actualTime: actualTime,
         orbitTime: orbitTime,
         spinTime: spinTime,
         screen: screen,
         camera: camera,
         bodies: [
           for (final body in bodies)
             body.poseAt(orbitTime: orbitTime, spinTime: spinTime),
         ],
       );

  /// The seconds that the frame loop has run. It stands still while the
  /// scene does.
  final double actualTime;

  /// The visitor sets the two clocks, so they can go back.
  final double orbitTime;
  final double spinTime;

  final Screen screen;
  final Camera camera;

  /// In page order.
  final List<BodyPose> bodies;
}
