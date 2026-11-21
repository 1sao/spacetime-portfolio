#version 460 core
#include <flutter/runtime_effect.glsl>
#include "sky.glsl"

// The sky baked on the lattice of uSkyCells cells on each face of the cube
// (see latticePlace in sky.glsl), by lib/scene/sky_cache.dart. The faces
// are in 3 columns and 2 rows, one pixel for each cell, which holds
// sqrt(colour / 2): the square root keeps more of the dim colours in 8
// bits.

out vec4 fragColor;

void main() {
  vec2 pixel = floor(FlutterFragCoord().xy);
  // The half pixel keeps the division from falling just under a whole
  // number at a face's first pixel.
  vec2 faceCell = floor((pixel + 0.5) / uSkyCells);
  int face = int(faceCell.x + 3.0 * faceCell.y);
  vec2 place = pixel - faceCell * uSkyCells + 0.5;
  vec3 colour = starNest(skyOrigin, latticeDirection(face, place));
  fragColor = vec4(sqrt(clamp(colour * 0.5, 0.0, 1.0)), 1.0);
}
