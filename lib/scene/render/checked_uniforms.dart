import 'dart:ui';

extension CheckedUniforms on FragmentShader {
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
