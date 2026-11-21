// Kepler 256o by otaviogood
// https://www.shadertoy.com/view/XsjGRd
// License: CC0
//
// Changed for this project: only the planet, its atmosphere's glow and the
// light's glare through it, as a function of a ray in the planet's own
// space. One light, the hole, in place of the two moving suns. The
// textures are read at the longitude and the height along the axis, so the
// planet can be seen from every side, and they are procedural
// (kepler_textures.frag).

// An Earth-like planet, for scene.frag. KeplerLook in lib/scene/looks.dart
// holds the look's values.
//
// The planet's space: the planet's centre is at 0, its radius is 1, and y
// is its axis.

struct Kepler {
  vec3 air;
  vec3 greenLand;
  vec3 dryLand;
  vec3 ice;
  vec3 clouds;
  float seaLevel;
  float dryness;
  vec3 glint;
  vec3 oceanReflection;
  vec3 glare;
  vec2 seed;
  // How far the planet has turned, in texture units: 4 is a turn.
  float spin;
  // How far the clouds have moved, in texture units.
  float cloudShift;
};

// The edge of the atmosphere's glow, in planet radii. distanceToBody in
// scene.frag finds the planet by it.
const float keplerGlowRadius = 1.05;

const float keplerPi = 3.14159265;

uniform sampler2D uSurface;
uniform sampler2D uNoise;
uniform sampler2D uDetail;

// The texels across uSurface, uNoise and uDetail, each with its border of
// one texel on each side (kepler_textures.frag).
uniform vec3 uTextureSizes;

// The point of a texture of size texels for uv, inside its border.
vec2 insideBorder(vec2 uv, float size) {
  return (fract(uv) * (size - 2.0) + 1.0) / size;
}

vec4 surface(vec2 uv) {
  return texture(uSurface, insideBorder(uv, uTextureSizes.x));
}

vec4 noise(vec2 uv) {
  return texture(uNoise, insideBorder(uv, uTextureSizes.y));
}

vec4 detail(vec2 uv) {
  return texture(uDetail, insideBorder(uv, uTextureSizes.z));
}

float saturate(float a) {
  return clamp(a, 0.0, 1.0);
}

// The light reflected on the oceans.
vec3 oceanGlint(Kepler look, vec3 direction, vec3 toLight) {
  float intensity = 1.0 - (dot(direction, toLight) * 0.5 + 0.5);
  intensity = min(0.2 / intensity, 40000.0);
  return look.oceanReflection * intensity;
}

// Where the line through origin along direction meets the sphere at the
// centre: entry and exit, or the nearest point twice if it misses. Gives 1
// on a hit, and the distance of the line from the sphere's surface.
float keplerSphere(
  float radius,
  vec3 origin,
  vec3 direction,
  out vec3 entry,
  out vec3 exit,
  out float distanceFromSphere
) {
  vec3 nearestPoint = origin - direction * dot(direction, origin);
  float distance = length(nearestPoint);
  float halfChord = sqrt(max(radius * radius - distance * distance, 0.0));
  entry = nearestPoint - direction * halfChord;
  exit = nearestPoint + direction * halfChord;
  distanceFromSphere = distance - radius;
  return distance <= radius ? 1.0 : 0.0;
}

vec2 spiral(vec2 uv, float blurriness) {
  vec2 cell = fract(uv * 2.0);
  vec2 delta = cell - 0.5;
  float distance = length(delta);
  vec2 offset = vec2(delta.y, -delta.x);
  float blend = pow(clamp((0.5 - distance) * 2.0, 0.0, 1.0), 1.5);
  return uv + offset * blend * 1.1 * blurriness;
}

// The premultiplied colour and the coverage along the ray from origin along
// direction, of length 1. The glow round the planet adds light, with a
// coverage of 0. light is the hole's position.
vec4 keplerRay(Kepler look, vec3 origin, vec3 direction, vec3 light) {
  vec3 glowEntry;
  vec3 glowExit;
  vec3 entry;
  vec3 exit;
  float distanceFromSphere;
  float isGlowHit = keplerSphere(
    keplerGlowRadius,
    origin,
    direction,
    glowEntry,
    glowExit,
    distanceFromSphere
  );
  float isHit = keplerSphere(
    1.0,
    origin,
    direction,
    entry,
    exit,
    distanceFromSphere
  );
  if (distanceFromSphere >= keplerGlowRadius - 1.0) return vec4(0.0);

  // On a miss, entry is the nearest point of the ray to the planet.
  vec3 normal = normalize(entry);
  vec3 toLight = normalize(light - entry);
  // The light is as bright as two suns.
  const float suns = 2.0;

  vec3 c = vec3(0.0);
  vec3 bumpedNormal = normal;
  vec3 glints = vec3(0.0);
  if (isHit > 0.0) {
    // The longitude, 4 texture units to a turn, and the height along the
    // axis.
    vec2 polar = vec2(
      atan(normal.z, normal.x) * 2.0 / keplerPi + look.spin,
      normal.y
    ) + look.seed;
    vec3 noiseValues = vec3(
      noise(polar * 2.0).x,
      noise(polar * 1.0).y,
      noise(polar * 4.0).z
    );
    // Read at one longitude: a turn of the planet is not a whole number of
    // turns of the texture at this scale.
    float blurriness = surface(vec2(look.seed.x, polar.y) * 0.03125 * 0.25).b;

    float tex = surface(polar).r;
    tex *= tex;
    float texFlip = surface(1.0 - polar * 0.5).r;
    texFlip *= texFlip;

    vec2 cloudPolar = spiral(polar, blurriness) + vec2(look.cloudShift, 0.0);
    float cloudTex = surface(cloudPolar).r;
    cloudTex *= cloudTex;
    float cloudTexFlip = surface(1.0 - cloudPolar * 0.5).r;
    cloudTexFlip *= cloudTexFlip;

    // Thicker toward the edge.
    float airDensity = 1.45 + dot(normal, direction);
    vec3 cloudDensity = max(
      vec3(0.0),
      pow(cloudTexFlip * cloudTex, 0.7) * look.clouds
    );
    c = look.air * airDensity + cloudDensity;

    vec3 detailMap = min(detail(polar * 2.0).xyz, 0.25) * 4.0;
    float land = pow(max(0.0, surface(polar * 0.25).g - look.seaLevel), 0.4) *
      0.75;
    float dryShare = max(0.0, land * blurriness * look.dryness);
    land *= detailMap.x;
    land = max(0.0, land - tex * 0.65);
    float iceFactor = normal.y * normal.y;
    vec3 mixedLand = (max(vec3(0.0), look.greenLand * land) +
      max(vec3(0.0), look.dryLand * dryShare)) * 0.5;
    mixedLand *= (detailMap.zyx + 2.0) * 0.333;
    vec3 finalLand = mix(mixedLand, look.ice * land, iceFactor);
    finalLand = mix(
      look.air * 0.05,
      finalLand,
      pow(min(1.0, max(0.0, -distanceFromSphere)), 0.2)
    );
    c += finalLand;

    float reflectionNoise = (noiseValues.x + noiseValues.y + noiseValues.z) *
      0.3333;
    bumpedNormal = normalize(
      normal + vec3(reflectionNoise * 0.05, tex * 0.1, texFlip * 0.1)
    );
    vec3 reflected = normalize(reflect(direction, bumpedNormal));
    reflectionNoise = reflectionNoise * 0.25 + 0.75;

    // Only where the light is behind the planet.
    float glance = saturate(
      dot(reflected, toLight) * saturate(dot(toLight, direction) - 0.65)
    );
    float landMask = finalLand.x + finalLand.y * 1.5;
    glints = oceanGlint(look, reflected, toLight) *
      (1.0 - saturate(landMask * 3.5)) *
      (1.0 - cloudTex) *
      reflectionNoise;
    glints = mix(glints, look.glint, glance) * suns;
  }
  c += glints;

  float outerGlow = pow(
    1.0 - clamp(distanceFromSphere * 20.0, 0.0, 1.0),
    5.2
  );
  c += (look.air + vec3(0.2)) * outerGlow * (1.0 - isHit);

  float lit = saturate(dot(toLight, bumpedNormal)) * suns;
  // The small constant is the light of the stars.
  c *= lit * 0.75 * uLight + 0.001 + uAmbient;
  c += isHit * uRim * uAmbient *
    pow(1.0 - abs(dot(direction, normal)), 3.0);

  float scattering = isGlowHit == 1.0 ? distance(glowEntry, glowExit) : 0.0;
  scattering *= pow(saturate(dot(direction, toLight) - 0.96), 2.0);
  scattering *= isGlowHit * (1.0 - isHit) * outerGlow * suns;
  c += look.glare * scattering;

  return vec4(sqrt(c), isHit);
}
