import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:spacetime_portfolio/scene/render/hole_textures.dart';
import 'package:spacetime_portfolio/scene/render/kepler_textures.dart';
import 'package:spacetime_portfolio/scene/render/looks.dart';
import 'package:spacetime_portfolio/scene/render/scene_assets.dart';
import 'package:spacetime_portfolio/scene/render/scene_shader.dart';
import 'package:spacetime_portfolio/space/camera/camera.dart';
import 'package:spacetime_portfolio/space/camera/direction_and_distance.dart';
import 'package:spacetime_portfolio/space/frame_snapshot.dart';
import 'package:spacetime_portfolio/space/rgb.dart';
import 'package:spacetime_portfolio/space/system/body.dart';
import 'package:spacetime_portfolio/space/system/body_look.dart';
import 'package:spacetime_portfolio/space/system/system.dart';
import 'package:vector_math/vector_math_64.dart' show Sphere, Vector2, Vector3;

import '../../blank_scene.dart';

void main() {
  // Pure colors, so each disk's pixels match exactly.
  const holeColor = SceneShader.placeholderHoleColor;
  const bodyColors = [
    Color(0xFFFF0000),
    Color(0xFF00FF00),
    Color(0xFF0000FF),
    Color(0xFFFF00FF),
  ];
  const looks = Looks(
    lighting: Lighting(direct: Rgb.gray(1), ambient: Rgb.gray(0), rim: 0),
  );
  // Large, and well off the view axis, so some disks are centered pixels
  // away from where their spheres' centers project (see _diskCenter).
  // Apart and inside the screen, so each disk is whole. Clear of the
  // lensing sphere, so the rays to each disk are straight.
  final bodies = [
    Sphere.centerRadius(Vector3(13, 2, -10), 1.8),
    Sphere.centerRadius(Vector3(-13, -3, -2), 1.4),
    Sphere.centerRadius(Vector3(2, 10, -6), 1.4),
    Sphere.centerRadius(Vector3(9, -7, -6), 1.6),
  ];
  final cameras = {
    'aimed at the hole': Camera(
      target: Vector3.zero(),
      fromTarget: const DirectionAndDistance(
        azimuth: 0.3,
        elevation: 0.14,
        distance: 84,
      ),
      focalLength: 420,
    ),
    'nearer, aimed off the center, which lands off the middle': Camera(
      target: Vector3(0, 1, 0),
      fromTarget: DirectionAndDistance.of(Vector3(28, 11, -56)),
      focalLength: 420,
      screenPoint: Vector2(0.45, 0.55),
    ),
    // Not a quarter turn, so that the view is not lined up with the
    // screen's axes.
    'rolled, with a shorter focal length': Camera(
      target: Vector3(0, 1, 0),
      fromTarget: DirectionAndDistance.of(Vector3(28, 11, -56)),
      focalLength: 300,
      screenPoint: Vector2(0.45, 0.55),
      roll: 0.6,
    ),
  };

  final disks = [
    (
      'the hole',
      Sphere.centerRadius(Vector3.zero(), holeShadowRadius),
      holeColor,
    ),
    for (final (i, body) in bodies.indexed) ('body $i', body, bodyColors[i]),
  ];

  /// The scene shader with [looks], a [FlatLook] of each of [bodyColors]
  /// and the hole drawn in [holeColor].
  Future<SceneShader> sceneShader() async {
    final program = await FragmentProgram.fromAsset(sceneShaderAsset);
    final holeTextures = HoleTextures.bake(
      await FragmentProgram.fromAsset(holeTexturesAsset),
      looks.hole,
    );
    addTearDown(holeTextures.dispose);
    // The placeholders leave the sky out, so baking it would be wasted.
    final skyCache = BlankSky();
    addTearDown(skyCache.dispose);
    final keplerTextures = KeplerTextures.blank();
    addTearDown(keplerTextures.dispose);
    final shader = SceneShader(
      program,
      looks,
      bodies: [for (final color in bodyColors) FlatLook(color.rgb)],
      keplerTextures: keplerTextures,
      holeTextures: holeTextures,
      skyCache: skyCache,
      usesPlaceholders: true,
    );
    addTearDown(shader.dispose);
    return shader;
  }

  testWidgets('the CPU projection matches where the shader draws the hole '
      'and the bodies outside the lensing distortion', (tester) async {
    // Rendering is engine work, which the test's fake clock would stall.
    await tester.runAsync(() async {
      final shader = await sceneShader();
      for (final MapEntry(key: name, value: camera) in cameras.entries) {
        final frame = _frame(camera, bodies);
        final pixels = await _render(shader, frame);

        for (final (disk, sphere, color) in disks) {
          final drawn = _centroid(
            pixels,
            _screen,
            color,
            // The hole is drawn inside the lensing sphere.
            straightTo: disk == 'the hole' ? null : (camera, sphere),
          );
          final expected = _diskCenter(camera, sphere, _screen);
          expect(drawn, isNotNull, reason: '$name: $disk is drawn');
          expect(expected, isNotNull, reason: '$name: $disk is in front');
          expect(
            drawn!.distanceTo(expected!),
            lessThan(0.25),
            reason: '$name: $disk at $drawn, expected at $expected',
          );
        }
      }
    });
  });

  testWidgets('a body inside the lensing sphere is drawn', (tester) async {
    await tester.runAsync(() async {
      final shader = await sceneShader();
      // Between the camera and the hole, so each ray to it enters the
      // sphere first.
      final camera = cameras['aimed at the hole']!;
      final inside = Sphere.centerRadius(
        camera.position.normalized() * (holeLensingRadius - 2.5),
        1,
      );
      final pixels = await _render(
        shader,
        _frame(camera, [inside, ...bodies.skip(1)]),
      );
      expect(_centroid(pixels, _screen, bodyColors[0]), isNotNull);
    });
  });
}

// Not square, so swapped width and height would show.
const _screen = Screen(width: 400, height: 250);

FrameSnapshot _frame(Camera camera, List<Sphere> bodies) => FrameSnapshot(
  actualTime: 0,
  orbitTime: 0,
  spinTime: 0,
  screen: _screen,
  camera: camera,
  bodies: [
    for (final sphere in bodies)
      BodyPose(
        sphere: sphere,
        reach: sphere.radius,
        spinAxis: Vector3(0, 1, 0),
        spinAngle: 0,
      ),
  ],
);

Future<ByteData> _render(SceneShader shader, FrameSnapshot frame) async {
  final screen = frame.screen;
  // The sky is off, so the pixel ratio does not change the picture.
  shader.set(frame, skyFocalLength: frame.camera.focalLength, pixelRatio: 1);
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

/// Where the center of [sphere]'s disk lands in [screen], in pixels, or
/// null if the sphere's center is behind the camera.
///
/// Perspective draws a sphere off the view axis as an ellipse, centered
/// farther out than [Camera.project] puts the sphere's center. If that
/// center is θ off the axis and the sphere spans α either side of it, its
/// edges land focalLength · tan(θ ± α) from where the view axis lands, and the
/// ellipse's center is midway between them. For radius r at distance d,
/// sin α = r / d, and the midpoint works out at d² / (d² − r² sec² θ) times
/// the projected center's focalLength · tan θ.
Vector2? _diskCenter(Camera camera, Sphere sphere, Screen screen) {
  final projected = camera.project(sphere.center, screen);
  if (projected == null) return null;
  final axis = camera.targetPixel(screen);
  final off = projected - axis;
  final d2 = sphere.center.distanceToSquared(camera.position);
  // tan θ is the projected center's distance from the axis over focalLength.
  final sec2 = 1 + off.length2 / (camera.focalLength * camera.focalLength);
  return axis + off * (d2 / (d2 - sphere.radius * sphere.radius * sec2));
}

/// The mean of the centers of the pixels drawn in [color], or null if
/// there are none. With [straightTo], only the pixels whose straight rays
/// from the camera reach the sphere before the lensing sphere count: the
/// bent rays can show images of the bodies around the hole.
Vector2? _centroid(
  ByteData pixels,
  Screen screen,
  Color color, {
  (Camera, Sphere)? straightTo,
}) {
  int byte(double channel) => (channel * 255).round();
  final (r, g, b) = (byte(color.r), byte(color.g), byte(color.b));
  final width = screen.width.toInt();

  final sum = Vector2.zero();
  var count = 0;
  for (var i = 0; i < pixels.lengthInBytes; i += 4) {
    if (pixels.getUint8(i) == r &&
        pixels.getUint8(i + 1) == g &&
        pixels.getUint8(i + 2) == b) {
      final index = i ~/ 4;
      final pixel = Vector2(index % width + 0.5, index ~/ width + 0.5);
      if (straightTo case (final camera, final sphere)
          when !camera.reachesFirst(sphere, pixel, screen)) {
        continue;
      }
      sum.add(pixel);
      count++;
    }
  }
  return count == 0 ? null : sum / count.toDouble();
}

extension on Camera {
  /// Whether the straight ray through [pixel] meets [sphere] before the
  /// lensing sphere.
  bool reachesFirst(Sphere sphere, Vector2 pixel, Screen screen) {
    final direction = rayThrough(pixel, screen);
    double? entry(Vector3 center, double radius) {
      final along = (center - position).dot(direction);
      final miss2 = (center - position).length2 - along * along;
      if (along <= 0 || miss2 >= radius * radius) return null;
      return along - math.sqrt(radius * radius - miss2);
    }

    final hit = entry(sphere.center, sphere.radius);
    final bend = entry(Vector3.zero(), holeLensingRadius);
    return hit != null && (bend == null || hit < bend);
  }
}

extension on Color {
  Rgb get rgb => Rgb(r, g, b);
}
