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
  SceneShader(FragmentProgram program, Looks looks)
    : this._(program.fragmentShader(), looks);

  SceneShader._(this.fragmentShader, Looks looks)
    : _size = fragmentShader.getUniformVec2('uSize'),
      _focal = fragmentShader.getSingleUniformFloat('uFocal'),
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
  }

  /// How many bodies the shader can draw. It has no arrays, so each body is
  /// its own uniform.
  static const bodySlots = 4;

  /// What a [Paint.shader] draws the scene with, once [set] has set this
  /// frame's uniforms.
  final FragmentShader fragmentShader;

  final UniformVec2Slot _size;
  final UniformFloatSlot _focal;
  final UniformVec3Slot _camera;
  final UniformVec3Slot _forward;
  final UniformVec3Slot _right;
  final UniformVec3Slot _up;
  final List<UniformVec4Slot> _bodies;

  /// Sets the uniforms that change from frame to frame: the camera and the
  /// bodies from [frame], and the drawn area from [screen].
  void set(FrameSnapshot frame, Screen screen) {
    final bodies = frame.bodies;
    assert(bodies.length <= bodySlots);
    _size.set(screen.width, screen.height);
    _focal.set(screen.focal);
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
