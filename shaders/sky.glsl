// Star Nest by Pablo Román Andrioli
// https://www.shadertoy.com/view/XlfGRj
// License: MIT
//
// Noise clamp: modifications by Beibei Wang and Huw Bowles.
// https://www.shadertoy.com/view/XllGzN
// License: MIT
//
// Changed for this project: a function of a direction instead of a full
// shader, a fixed origin and a direction lattice. The full licence text is
// in LICENSES/star-nest.txt.

// The sky: a nebula with stars, the same in every frame for a direction.
//
// sky_cache.frag bakes it on a lattice of directions, which scene.frag reads
// behind the bodies. The sky depends on the direction only, so it turns with
// the camera and does not change when the camera moves.
//
// Star Nest takes samples of a fractal at points along the ray, and adds
// their light. The fractal is bright where it is chaotic.
//
// The names here are the original's as follows: volsteps = skySteps,
// stepsize = skyStepLength, iterations = fractalIterations, formuparam =
// fractalOffset, tile = tileSize, brightness = skyBrightness, darkmatter =
// darkMatter, distfading = fadePerStep, saturation = skySaturation, r =
// sampleIndex, s = depth, p = point, pa = previousLength, a = totalJump,
// dm = darkness, v = light.

// The number of lattice cells across each face of the cube around the
// camera (see latticePlace). scene_shader.dart sets it from the size of a
// pixel.
uniform float uSkyCells;

// The number of samples along each ray, and the distance between them.
const int skySteps = 20;
const float skyStepLength = 0.1;
// Each sample counts 0.73 times as much as the one before it, so the far
// samples are fainter.
const float fadePerStep = 0.73;

// The number of times the fractal's formula is applied at each sample.
const int fractalIterations = 17;
// The noise clamp limits the jumps of the last iterations, which are the
// finest detail and give most of the noise. The first iterations keep the
// original formula, which keeps the volume of the nebula.
const int unclampedIterations = 14;
const float maxJump = 12.0;
// The constant that the fractal's formula subtracts in each iteration.
const float fractalOffset = 0.53;
// The size of the cube that the fractal sees. Space is filled with copies
// of this cube, each the mirror image of the one beside it, so the copies
// join without seams. The pattern repeats every two copies, 2 tileSize.
const float tileSize = 0.85;

const float skyBrightness = 0.0015;
// How much the empty parts of the fractal dim the samples behind them.
const float darkMatter = 0.3;
// 1 keeps the colours, 0 makes them grey.
const float skySaturation = 0.85;

// Where every ray starts in the fractal. A different origin gives a
// different sky.
const vec3 skyOrigin = vec3(0.674, 0.425, 0.176);

// The light that a ray from origin along direction collects, red, green and
// blue. direction has length 1.
vec3 starNest(vec3 origin, vec3 direction) {
  // depth goes from 0.1 to 2.0 in steps of skyStepLength. The sample is
  // depth / 2 along the ray, and depth also gives the sample its colour.
  float depth = 0.1;
  float fade = 1.0;
  vec3 light = vec3(0.0);
  for (int sampleIndex = 0; sampleIndex < skySteps; sampleIndex++) {
    vec3 point = origin + depth * 0.5 * direction;
    // Fold space into the cube from 0 to tileSize on each axis (see
    // tileSize). mod gives 0 to 2 tileSize, the subtraction -tileSize to
    // tileSize, and abs 0 to tileSize.
    point = abs(vec3(tileSize) - mod(point, vec3(tileSize * 2.0)));

    // The fractal: each iteration sends the point to abs(point) / |point|²
    // minus fractalOffset. totalJump adds how much the point's distance from
    // the origin changes in each iteration. In chaotic parts of the fractal it
    // jumps a lot, and the sample is bright.
    float previousLength = 0.0;
    float totalJump = 0.0;
    // |point|², kept from one iteration to the next, where it divides.
    float lengthSquared = dot(point, point);
    // The clamped iterations have their own loop, so no iteration tests
    // its index. One inverse square root gives both 1 / |point|² and
    // |point|.
    float inverseLength = inversesqrt(lengthSquared);
    for (int i = 0; i < unclampedIterations; i++) {
      point = abs(point) * (inverseLength * inverseLength) - fractalOffset;
      lengthSquared = dot(point, point);
      inverseLength = inversesqrt(lengthSquared);
      float pointLength = lengthSquared * inverseLength;
      totalJump += abs(pointLength - previousLength);
      previousLength = pointLength;
    }
    for (int i = unclampedIterations; i < fractalIterations; i++) {
      point = abs(point) * (inverseLength * inverseLength) - fractalOffset;
      lengthSquared = dot(point, point);
      inverseLength = inversesqrt(lengthSquared);
      float pointLength = lengthSquared * inverseLength;
      totalJump += min(maxJump, abs(pointLength - previousLength));
      previousLength = pointLength;
    }

    // Where the fractal is calm, dark matter dims the samples behind it.
    // The first samples are not dimmed, so the near nebula stays clear.
    float darkness = max(0.0, darkMatter - totalJump * totalJump * 0.001);
    // The cube gives more contrast between calm and chaotic parts.
    totalJump *= totalJump * totalJump;
    if (sampleIndex > 6) fade *= 1.0 - darkness;

    // A faint glow from every sample, and the sample's own light. Its
    // colour comes from its depth: red, green and blue are depth, depth²
    // and depth⁴, so near samples are red and far ones blue.
    light += fade;
    light += vec3(depth, depth * depth, depth * depth * depth * depth) *
      totalJump * skyBrightness * fade;

    fade *= fadePerStep;
    depth += skyStepLength;
  }
  // Mix with a grey that has the length of light, √(r² + g² + b²), in each
  // channel (see skySaturation).
  light = mix(vec3(length(light)), light, skySaturation);
  return light * 0.01;
}

// The cube around the camera: face 0 looks along +x, 1 along -x, 2 along
// +y, 3 along -y, 4 along +z and 5 along -z. normal is the direction the
// face looks along; across and along span the face.
void faceBasis(int face, out vec3 normal, out vec3 across, out vec3 along) {
  if (face == 0) {
    normal = vec3(1.0, 0.0, 0.0);
    across = vec3(0.0, 0.0, 1.0);
    along = vec3(0.0, 1.0, 0.0);
  } else if (face == 1) {
    normal = vec3(-1.0, 0.0, 0.0);
    across = vec3(0.0, 0.0, -1.0);
    along = vec3(0.0, 1.0, 0.0);
  } else if (face == 2) {
    normal = vec3(0.0, 1.0, 0.0);
    across = vec3(1.0, 0.0, 0.0);
    along = vec3(0.0, 0.0, 1.0);
  } else if (face == 3) {
    normal = vec3(0.0, -1.0, 0.0);
    across = vec3(1.0, 0.0, 0.0);
    along = vec3(0.0, 0.0, -1.0);
  } else if (face == 4) {
    normal = vec3(0.0, 0.0, 1.0);
    across = vec3(-1.0, 0.0, 0.0);
    along = vec3(0.0, 1.0, 0.0);
  } else {
    normal = vec3(0.0, 0.0, -1.0);
    across = vec3(1.0, 0.0, 0.0);
    along = vec3(0.0, 1.0, 0.0);
  }
}

// The lattice: a fixed set of directions that the sky is taken at.
//
// A star in the fractal can be smaller than a pixel. If each pixel took the
// sky at its own direction, a small turn of the camera would make such a
// star appear and disappear: it blinks. sky_cache.frag takes the sky once
// at each direction of the lattice, and scene.frag blends the nearest four,
// so as the view turns a star moves from pixel to pixel.
//
// The lattice divides each face of the cube around the camera into
// uSkyCells by uSkyCells cells. The cells are equal in angle, not in size
// on the face: a face spans pi/2 rad in each direction, and each cell
// pi / (2 uSkyCells) rad. A cell narrower than a pixel can get no pixel,
// and then its stars blink again, so scene_shader.dart makes the cells
// wider than a pixel.

// The face that direction goes through, and where on that face, in cells
// from its corner: the middle of cell (i, j) is at (i + 0.5, j + 0.5).
vec2 latticePlace(vec3 direction, out int face) {
  // The face is the one on the axis along which direction goes furthest.
  vec3 size = abs(direction);
  face = size.x >= size.y && size.x >= size.z ? (direction.x > 0.0 ? 0 : 1)
    : size.y >= size.z ? (direction.y > 0.0 ? 2 : 3)
    : (direction.z > 0.0 ? 4 : 5);
  vec3 normal;
  vec3 across;
  vec3 along;
  faceBasis(face, normal, across, along);
  // The direction's two angles from the face's middle, each from -pi/4 to
  // pi/4.
  vec2 angles = atan(
    vec2(dot(direction, across), dot(direction, along)) /
      dot(direction, normal)
  );
  return angles / (1.5707963 / uSkyCells) + 0.5 * uSkyCells;
}

// The direction through place on face (see latticePlace), of length 1.
vec3 latticeDirection(int face, vec2 place) {
  vec3 normal;
  vec3 across;
  vec3 along;
  faceBasis(face, normal, across, along);
  vec2 slopes = tan((place - 0.5 * uSkyCells) * (1.5707963 / uSkyCells));
  return normalize(normal + slopes.x * across + slopes.y * along);
}
