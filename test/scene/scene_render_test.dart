import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:homepage_v2/scene/looks.dart';
import 'package:homepage_v2/scene/scene_shader.dart';
import 'package:homepage_v2/scene/scene_view.dart';
import 'package:homepage_v2/space/camera.dart';
import 'package:homepage_v2/space/camera_rig.dart';
import 'package:homepage_v2/space/frame.dart';
import 'package:homepage_v2/space/site_space.dart';
import 'package:vector_math/vector_math_64.dart' show Sphere, Vector2, Vector3;

void main() {
  // Pure colours, so each disc's pixels match exactly.
  const looks = Looks(
    centralBody: Color(0xFFFFFFFF),
    bodies: [
      Color(0xFFFF0000),
      Color(0xFF00FF00),
      Color(0xFF0000FF),
      Color(0xFFFF00FF),
    ],
  );
  // Not square, so swapped width and height would show.
  const screen = Screen(width: 400, height: 250);
  // Large, and up to 42° off the view axis, so some discs are centred
  // pixels away from where their spheres' centres project (see
  // _discCentre). Apart and inside the screen, so each disc is whole.
  final bodies = [
    Sphere.centerRadius(Vector3(13, 2, -10), 1.8),
    Sphere.centerRadius(Vector3(-11, -3, 2), 1.4),
    Sphere.centerRadius(Vector3(2, 10, -6), 1.4),
    Sphere.centerRadius(Vector3(9, -7, -6), 1.6),
  ];
  final cameras = {
    'overview': CameraRig(
      target: Vector3.zero(),
      yaw: 0.3,
      pitch: 0.14,
      distance: 30,
    ).camera,
    'nearer, aimed off the centre': Camera(
      position: Vector3(10, 5, -20),
      target: Vector3(0, 1, 0),
    ),
  };

  final discs = [
    (
      'the central body',
      Sphere.centerRadius(Vector3.zero(), centralBody.radius),
      looks.centralBody,
    ),
    for (final (i, body) in bodies.indexed) ('body $i', body, looks.bodies[i]),
  ];

  testWidgets('the CPU projection lands on each disc the shader draws', (
    tester,
  ) async {
    // Rendering is engine work, which the test's fake clock would stall.
    await tester.runAsync(() async {
      final program = await FragmentProgram.fromAsset(sceneShaderAsset);
      final shader = SceneShader(program, looks);
      addTearDown(shader.dispose);

      for (final MapEntry(key: name, value: camera) in cameras.entries) {
        final frame = FrameSnapshot(time: 0, camera: camera, bodies: bodies);
        final pixels = await _render(shader, frame, screen);

        for (final (disc, sphere, colour) in discs) {
          final drawn = _centroid(pixels, screen, colour);
          final expected = _discCentre(camera, sphere, screen);
          expect(drawn, isNotNull, reason: '$name: $disc is drawn');
          expect(expected, isNotNull, reason: '$name: $disc is in front');
          expect(
            drawn!.distanceTo(expected!),
            lessThan(0.25),
            reason: '$name: $disc at $drawn, expected at $expected',
          );
        }
      }
    });
  });
}

Future<ByteData> _render(
  SceneShader shader,
  FrameSnapshot frame,
  Screen screen,
) async {
  shader.set(frame, screen);
  final recorder = PictureRecorder();
  Canvas(recorder).drawRect(
    Rect.fromLTWH(0, 0, screen.width, screen.height),
    Paint()..shader = shader.fragmentShader,
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(
    screen.width.toInt(),
    screen.height.toInt(),
  );
  picture.dispose();
  final pixels = await image.toByteData();
  image.dispose();
  return pixels!;
}

/// Where the centre of [sphere]'s disc lands in [screen], in pixels, or
/// null if the sphere's centre is behind the camera.
///
/// Perspective draws a sphere off the view axis as an ellipse, centred
/// further out than [Camera.project] puts the sphere's centre. If that
/// centre is θ off the axis and the sphere spans α either side of it, its
/// edges land focal · tan(θ ± α) from the middle of the screen, and the
/// ellipse's centre is midway between them. For radius r at distance d,
/// sin α = r / d, and the midpoint works out at d² / (d² − r² sec² θ) times
/// the projected centre's focal · tan θ.
Vector2? _discCentre(Camera camera, Sphere sphere, Screen screen) {
  final projected = camera.project(sphere.center, screen);
  if (projected == null) return null;
  final middle = Vector2(screen.width / 2, screen.height / 2);
  final off = projected - middle;
  final d2 = sphere.center.distanceToSquared(camera.position);
  // tan θ is the projected centre's distance from the middle over focal.
  final sec2 = 1 + off.length2 / (screen.focal * screen.focal);
  return middle + off * (d2 / (d2 - sphere.radius * sphere.radius * sec2));
}

/// The mean of the centres of the pixels drawn in [colour], or null if
/// there are none.
Vector2? _centroid(ByteData pixels, Screen screen, Color colour) {
  int byte(double channel) => (channel * 255).round();
  final (r, g, b) = (byte(colour.r), byte(colour.g), byte(colour.b));
  final width = screen.width.toInt();

  final sum = Vector2.zero();
  var count = 0;
  for (var i = 0; i < pixels.lengthInBytes; i += 4) {
    if (pixels.getUint8(i) == r &&
        pixels.getUint8(i + 1) == g &&
        pixels.getUint8(i + 2) == b) {
      final pixel = i ~/ 4;
      sum.add(Vector2(pixel % width + 0.5, pixel ~/ width + 0.5));
      count++;
    }
  }
  return count == 0 ? null : sum / count.toDouble();
}
