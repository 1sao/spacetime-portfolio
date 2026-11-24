// Planet Shader by mrange
// https://www.shadertoy.com/view/3d2fDw
// License: CC0
//
// Changed for this project: only the planet and its rings, as a function of
// a ray in the planet's own space, lit from the hole. tanh is
// written out, because Flutter's web shaders do not have it.

// A banded planet with rings, for scene.frag. RingedLook in
// lib/space/body_look.dart holds the look's values.
//
// The planet's space: the planet's center is at 0, its radius is
// ringedRadius, and y is its axis. The rings are in the plane y = 0.
//
// Two shortcuts: the rings are shaded once for each pixel, averaged over it
// (ringsAlong), and a pixel takes one sample where four would be the same
// (isRingedSmooth).
//
// The names here are the original's as follows: planetRadii =
// ringedRadius, uBeer = absorption, sf = thickness, sl = thinness, sbeer =
// throughEdge, srayl = edgeness, slat = latitude, pl = ringRadius, pdf =
// ringDistance, rsd = toRingPlane, rsp = ringPoint, psi = shadowChord, cold
// = nearestSoFar, si = planetSpan.

struct Ringed {
  vec3 base;
  vec3 wideBand;
  vec3 thinBand;
  vec3 darkBand;
  vec4 bandFrequencies;
  vec3 rim;
  vec3 absorption;
  vec3 ringColor;
  vec3 ringStripeColor;
  // The middle radius of the rings, then three widths, in the planet's
  // space.
  vec4 ringLayout;
  vec4 ringFrequencies;
  float ringOpacity;
};

const float ringedRadius = 10.0;

// How far the rings reach either side of their middle radius: the sum of
// their three widths (see Ringed.ringLayout).
float ringHalfWidth(vec4 ringLayout) {
  return ringLayout.y + ringLayout.z + ringLayout.w;
}
const float ringedPi = 3.141592654;

vec3 tanh3(vec3 c) {
  return 1.0 - 2.0 / (exp(2.0 * c) + 1.0);
}

// Where the ray from origin along direction is inside a sphere at the
// planet's center: the distances along the ray to where it goes in and out.
// Both are -1 if the ray misses it.
vec2 ringedSphereSpan(vec3 origin, vec3 direction, float radius) {
  float b = dot(origin, direction);
  float c = dot(origin, origin) - radius * radius;
  if (c > 0.0 && b > 0.0) return vec2(-1.0);
  float discriminant = b * b - c;
  if (discriminant < 0.0) return vec2(-1.0);
  float s = sqrt(discriminant);
  return vec2(-b - s, -b + s);
}

vec3 scaleColor(vec3 c, float s, float r) {
  float o = sqrt(s / r);
  float i = s / o;
  return tanh3(c * i) * o;
}

// The glow of the light seen along direction: a small bright core and a
// wider glow.
vec3 lightGlow(vec3 direction, vec3 toLight) {
  float diff = max(dot(direction, toLight), 0.0);
  vec3 c = vec3(0.0);
  c += scaleColor(pow(diff, 4.0 * 200.0) * uLight, 8.0, 0.25);
  c += scaleColor(pow(diff, 4.0 * 50.0) * uLight, 1.0, 0.25);
  return c;
}

float positiveSin(float a) {
  return 0.5 + 0.5 * sin(a);
}

float positiveCos(float a) {
  return 0.5 + 0.5 * cos(a);
}

// cos(a), faded to 0 where a changes by half a cycle or more over the
// footprint, by footprintAngle. The pixels cannot show a faster wave, so
// it would show as a false slower one.
float fadedCos(float a, float footprintAngle) {
  float fade =
    1.0 - smoothstep(0.25 * ringedPi, ringedPi, abs(footprintAngle));
  return cos(a) * fade;
}

// The product of 0.5 + 0.5 cos(a) for the three angles a, averaged over
// the footprint, where a changes by footprintAngles. The product is a sum
// of waves at the sums and differences of the three frequencies, and each
// wave fades by its own frequency.
float averagedRipples(vec3 a, vec3 footprintAngles) {
  vec3 w = footprintAngles;
  float pairs =
    fadedCos(a.x + a.y, w.x + w.y) + fadedCos(a.x - a.y, w.x - w.y) +
    fadedCos(a.x + a.z, w.x + w.z) + fadedCos(a.x - a.z, w.x - w.z) +
    fadedCos(a.y + a.z, w.y + w.z) + fadedCos(a.y - a.z, w.y - w.z);
  float triples =
    fadedCos(a.x + a.y + a.z, w.x + w.y + w.z) +
    fadedCos(a.x + a.y - a.z, w.x + w.y - w.z) +
    fadedCos(a.x - a.y + a.z, w.x - w.y + w.z) +
    fadedCos(-a.x + a.y + a.z, -w.x + w.y + w.z);
  return (
    1.0 + fadedCos(a.x, w.x) + fadedCos(a.y, w.y) + fadedCos(a.z, w.z) +
    0.5 * pairs + 0.25 * triples
  ) / 8.0;
}

// The color and opacity of the rings at ringRadius from the center,
// averaged over footprint, the width of ring plane that the pixel covers.
// The opacity inside a band is raised to opacityPower.
vec4 rings(
  Ringed look,
  float ringRadius,
  float footprint,
  float opacityPower
) {
  // Each abs folds the distance, so one band becomes two with a gap.
  float ringDistance = ringRadius - look.ringLayout.x;
  ringDistance = abs(ringDistance) - look.ringLayout.y;
  ringDistance = abs(ringDistance) - look.ringLayout.z;
  ringDistance = abs(ringDistance) - look.ringLayout.w;
  vec4 c = vec4(1.0);
  c.rgb = mix(
    look.ringColor,
    look.ringStripeColor,
    0.5 - 0.5 * fadedCos(
      look.ringFrequencies.w * ringRadius,
      look.ringFrequencies.w * footprint
    )
  ) * uLight;
  c.rgb = pow(c.rgb, vec3(0.75));
  vec3 phases = look.ringFrequencies.xyz * ringRadius - 0.5 * ringedPi;
  vec3 footprintAngles = look.ringFrequencies.xyz * footprint;
  c.a = pow(
    max(averagedRipples(phases, footprintAngles) * look.ringOpacity, 0.0),
    opacityPower
  );
  // The share of the footprint inside a band. It stays outside the pow, so
  // that the band edges stay smooth.
  c.a *= clamp(0.5 - ringDistance / footprint, 0.0, 1.0);
  return c;
}

// The planet's color where the ray hits it, from planetSpan.x to
// planetSpan.y along the ray. light is the hole's position.
vec3 ringedPlanet(
  Ringed look,
  vec3 origin,
  vec3 direction,
  vec2 planetSpan,
  vec3 light
) {
  vec3 point = origin + direction * planetSpan.x;
  vec3 normal = normalize(point);
  vec3 toLight = normalize(light - point);
  vec3 reflected = reflect(direction, normal);
  vec3 reflection = lightGlow(reflected, toLight);
  float fresnel = pow(1.0 - abs(dot(direction, normal)), 15.0);
  float diffuse = max(dot(toLight, normal), 0.0);
  // How much of the planet the ray goes through, from 0 at the edge to 1
  // through the center. Light shines through where it is thin.
  float thickness = (planetSpan.y - planetSpan.x) / (2.0 * ringedRadius);
  float thinness = 1.0 - smoothstep(0.2, 0.7, thickness);
  vec3 throughEdge = exp(-6.0 * look.absorption * thickness) * thinness;
  float edgeness = pow(1.0 - abs(dot(direction, normal)), 5.0);

  float latitude = ringedPi * point.y / ringedRadius;
  vec3 c = look.base;
  vec4 f = look.bandFrequencies;
  c = mix(c, look.wideBand, pow(positiveCos(f.x * latitude), 5.0));
  c = mix(c, look.thinBand, pow(positiveCos(f.y * latitude), 20.0));
  c = mix(
    c,
    look.darkBand,
    pow(positiveCos(f.z * latitude) * positiveCos(f.w * latitude + 1.0), 15.0)
  );
  c = tanh3(c);
  c *= pow(uLight, vec3(0.66));
  c += look.rim * edgeness;

  return fresnel * reflection +
    pow(lightGlow(direction, toLight), vec3(0.85)) * throughEdge +
    c * (pow(diffuse, 0.75) + uAmbient) +
    uRim * uAmbient * edgeness;
}

// How far from the planet's center the ray meets the ring plane.
float ringPlaneRadius(vec3 origin, vec3 direction) {
  float dirY = sign(direction.y) * max(abs(direction.y), 1e-6);
  return length((origin - direction * (origin.y / dirY)).xz);
}

// The color and opacity of the rings where the ray meets them, averaged
// over footprint, how much the ring radius changes over the pixel. 0
// where the ray misses them.
vec4 ringsAlong(
  Ringed look,
  vec3 origin,
  vec3 direction,
  vec3 light,
  float footprint
) {
  float toRingPlane = -origin.y / direction.y;
  if (toRingPlane <= 0.0) return vec4(0.0);
  vec3 ringPoint = origin + direction * toRingPlane;
  float ringRadius = length(ringPoint.xz);
  float halfWidth = ringHalfWidth(look.ringLayout);
  // The outermost edges fade over half a footprint outside the rings.
  if (abs(ringRadius - look.ringLayout.x) > halfWidth + 0.5 * footprint) {
    return vec4(0.0);
  }
  // A ring seen at a low angle is more opaque.
  vec4 ring = rings(look, ringRadius, footprint, pow(abs(direction.y), 0.4));

  // The planet's shadow on the rings.
  vec2 shadowChord = ringedSphereSpan(
    ringPoint,
    normalize(light - ringPoint),
    ringedRadius
  );
  float shadowDepth = (shadowChord.y - shadowChord.x) / (2.0 * ringedRadius);
  ring.rgb *= 1.0 - smoothstep(0.0, 1.0, shadowDepth);
  return ring;
}

// The premultiplied color and the coverage along one ray, with ring from
// ringsAlong for the pixel. Nothing farther than maxDistance is drawn,
// because the body there hides it.
vec4 ringedRay(
  Ringed look,
  vec3 origin,
  vec3 direction,
  vec3 light,
  float maxDistance,
  vec4 ring
) {
  vec4 c = vec4(0.0);
  float nearestSoFar = maxDistance;

  vec2 planetSpan = ringedSphereSpan(origin, direction, ringedRadius);
  if (planetSpan.x < planetSpan.y && planetSpan.x < nearestSoFar) {
    c = vec4(ringedPlanet(look, origin, direction, planetSpan, light), 1.0);
    nearestSoFar = planetSpan.x;
  }

  float toRingPlane = -origin.y / direction.y;
  if (toRingPlane <= 0.0 || toRingPlane >= nearestSoFar) return c;
  return mix(c, vec4(ring.rgb, 1.0), ring.a);
}

vec3 ringedPostProcess(vec3 c) {
  c = pow(clamp(c, 0.0, 1.0), vec3(0.75));
  c = c * 0.6 + 0.4 * c * c * (3.0 - 2.0 * c);
  c = mix(c, vec3(dot(c, vec3(0.33))), -0.4);
  return c;
}

// True where one sample gives the same color as four: the ray hits the
// planet well inside its edge, no ring is in front of it, and the fastest
// band turns by less than a third of a radian per pixel. pixelSlope is the
// angle of one drawn pixel, in rad.
bool isRingedSmooth(
  Ringed look,
  vec3 origin,
  vec3 direction,
  float pixelSlope
) {
  vec2 planetSpan = ringedSphereSpan(origin, direction, ringedRadius);
  if (!(planetSpan.x < planetSpan.y && planetSpan.x > 0.0)) return false;
  vec3 normal = (origin + direction * planetSpan.x) / ringedRadius;
  float facing = -dot(direction, normal);
  // The size of a pixel on the planet, longer where the surface slants.
  float pixel = pixelSlope * planetSpan.x / max(facing, 1e-3);
  vec4 f = look.bandFrequencies;
  float fastest = ringedPi / ringedRadius * max(max(f.x, f.y), max(f.z, f.w));
  float toRingPlane = -origin.y / direction.y;
  float ringRadius = length((origin + direction * toRingPlane).xz);
  float reach = ringHalfWidth(look.ringLayout) + pixel * 4.0;
  bool isRingInFront = toRingPlane > 0.0 &&
    toRingPlane < planetSpan.x + pixel * 4.0 &&
    abs(ringRadius - look.ringLayout.x) < reach;
  return facing > 0.15 && fastest * pixel < 0.33 && !isRingInFront;
}
