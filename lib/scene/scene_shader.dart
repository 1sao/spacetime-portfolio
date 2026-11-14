import 'dart:math' as math;
import 'dart:ui';

import 'package:vector_math/vector_math_64.dart';

import '../space/camera.dart';
import '../space/frame_snapshot.dart';
import '../space/site_space.dart';
import 'looks.dart';

/// The scene's shader, `shaders/scene.frag`, ready to draw.
///
/// This is the single place where the shader is created and its uniforms
/// are set. The constructor looks each uniform up by name and throws if one
/// is missing from the shader or has a different type, so renaming or
/// retyping a uniform on one side only fails as soon as the shader loads.
class SceneShader {
  /// With [placeholders], the shader draws black in place of the sky, for
  /// the render test.
  SceneShader(FragmentProgram program, Looks looks, {bool placeholders = false})
    : this._(program.fragmentShader(), looks, placeholders: placeholders);

  SceneShader._(this.fragmentShader, Looks looks, {required bool placeholders})
    : _size = fragmentShader.getUniformVec2('uSize'),
      _focal = fragmentShader.getSingleUniformFloat('uFocal'),
      _skyCells = fragmentShader.getSingleUniformFloat('uSkyCells'),
      _camera = fragmentShader.getUniformVec3('uCamera'),
      _forward = fragmentShader.getUniformVec3('uForward'),
      _right = fragmentShader.getUniformVec3('uRight'),
      _up = fragmentShader.getUniformVec3('uUp'),
      _bodies = [
        for (var i = 0; i < bodySlots; i++)
          fragmentShader.getUniformVec4('uBody$i'),
      ] {
    if (looks.bodies.length != bodySlots) {
      throw ArgumentError('Looks need $bodySlots body colours.', 'looks');
    }
    fragmentShader
        .getSingleUniformFloat('uCentralBodyRadius')
        .set(centralBody.radius);
    fragmentShader
        .getUniformVec3('uCentralBodyColour')
        .setColour(looks.centralBody);
    for (var i = 0; i < bodySlots; i++) {
      fragmentShader.getUniformVec3('uColour$i').setColour(looks.bodies[i]);
    }
    fragmentShader
        .getSingleUniformFloat('uPlaceholders')
        .set(placeholders ? 1 : 0);
  }

  /// How many bodies the shader can draw. It has no arrays, so each body is
  /// its own uniform.
  static const bodySlots = 4;

  /// What a [Paint.shader] draws the scene with, once [set] has set this
  /// frame's uniforms.
  final FragmentShader fragmentShader;

  final UniformVec2Slot _size;
  final UniformFloatSlot _focal;
  final UniformFloatSlot _skyCells;
  final UniformVec3Slot _camera;
  final UniformVec3Slot _forward;
  final UniformVec3Slot _right;
  final UniformVec3Slot _up;
  final List<UniformVec4Slot> _bodies;

  /// Sets the uniforms that change from frame to frame: the camera and the
  /// bodies from [frame], and the drawn area from [screen], which has
  /// [pixelRatio] device pixels for each of its logical pixels.
  void set(FrameSnapshot frame, Screen screen, double pixelRatio) {
    final bodies = frame.bodies;
    assert(bodies.length <= bodySlots);
    _size.set(screen.width, screen.height);
    _focal.set(screen.focal);
    _skyCells.set(screen.skyCells(pixelRatio));
    final camera = frame.camera;
    _camera.setVector(camera.position);
    _forward.setVector(camera.forward);
    _right.setVector(camera.right);
    _up.setVector(camera.up);
    for (var i = 0; i < bodySlots; i++) {
      if (i < bodies.length) {
        _bodies[i].setSphere(bodies[i]);
      } else {
        // A radius of 0 leaves the slot empty.
        _bodies[i].set(0, 0, 0, 0);
      }
    }
  }

  void dispose() => fragmentShader.dispose();
}

extension _SkyLattice on Screen {
  /// The number of cells across each face of the sky's lattice
  /// (`snapToLattice` in `shaders/sky.glsl`), so that every cell gets at
  /// least one device pixel.
  ///
  /// A face spans π/2 rad, so each of its N cells spans π/(2N) rad. At the
  /// middle of the screen, a device pixel spans 1/(focal · pixelRatio) rad,
  /// because [focal] is in logical pixels per unit of slope. So with
  /// N = π/2 · focal · pixelRatio, a cell is one pixel wide there.
  ///
  /// But a cell can be narrower than that: near an edge of the cube, a cell
  /// is cos(π/4) ≈ 0.71 as wide along the edge. And when the view is turned
  /// against the cube, the pixel grid is turned against the cells. A cell
  /// narrower than a pixel can get no pixel, and then its stars blink.
  /// [_skyCellsPerPixel] makes the cells wider than a pixel.
  ///
  /// N is a multiple of 32. Because N is even, the edge of the face at π/4
  /// is a cell edge, so there are no narrow cells along the cube's edges.
  /// The steps of 32 also keep the lattice the same through small changes
  /// of the screen size, such as a phone's address bar.
  double skyCells(double pixelRatio) {
    final cells = _skyCellsPerPixel * math.pi / 2 * focal * pixelRatio;
    return math.max(1, (cells / 32).round()) * 32.0;
  }
}

/// The sky's lattice cells per device pixel at the middle of the screen.
///
/// Chosen with a simulation of the lattice at 1280x800 at a pixel ratio of
/// 2, over 15 views from straight ahead to near straight down: with 1, about
/// 14 % of the cells get no pixel; with 0.7, up to 4 %; with 0.65, none. A
/// smaller number makes the stars more blocky.
const _skyCellsPerPixel = 0.65;

extension _CheckedUniforms on FragmentShader {
  /// The uniform [name], which must be a single float.
  ///
  /// [FragmentShader.getUniformFloat] doesn't check the type: given a vector
  /// uniform, it returns the vector's first component. This throws instead.
  UniformFloatSlot getSingleUniformFloat(String name) {
    final floats = getUniformFloatArray(name);
    if (floats.length != 1) {
      throw ArgumentError(
        'Uniform `$name` has ${floats.length} floats, not 1.',
      );
    }
    return floats[0];
  }
}

extension _Vec3Values on UniformVec3Slot {
  void setVector(Vector3 vector) => set(vector.x, vector.y, vector.z);

  void setColour(Color colour) => set(colour.r, colour.g, colour.b);
}

extension _SphereValue on UniformVec4Slot {
  /// Sets [sphere] as the shader reads it: its centre in xyz and its radius
  /// in w.
  void setSphere(Sphere sphere) {
    final centre = sphere.center;
    set(centre.x, centre.y, centre.z, sphere.radius);
  }
}
