#version 460 core
#include <flutter/runtime_effect.glsl>
#include "sky.glsl"
#include "hole.glsl"

// The scene: the hole with its disk, and up to four bodies, over the sky
// (sky.glsl). Each body is drawn in its own kind of look: a sphere of one
// color, a banded planet with or without rings (planet_ringed.glsl), or an
// Earth-like planet (planet_kepler.glsl).
//
// A fragment shader runs once for every pixel and returns that pixel's color.
// This one casts a ray from the camera through the pixel. The ray is a chain of
// straight pieces. A ray that enters the hole's lensing sphere has one piece to
// the sphere, short ones along the bent path inside it (from the path table in
// hole.glsl), and one after it; any other ray is one piece. Along the way it
// gathers the hole's light (its disk, its jets and the glow around its shadow)
// and finds the first two bodies it meets. It shades them over the sky where
// they let it through. Two, so that a body shows through the rings and soft
// edges of the body in front of it.
//
// lib/scene/scene_shader.dart sets the uniforms by name. Positions and
// lengths are in world units. Colors are red, green and blue, where 1 is
// full brightness; light can go above 1.

// Where the camera's target lands, in logical pixels from the top left.
uniform vec2 uTargetPixel;
// Drawn pixels for each logical pixel: device pixels, or fewer for a soft
// scene.
uniform float uPixelRatio;
// For a soft scene, which is drawn smaller and scaled up (SceneSoftness in
// lib/scene/scene_view.dart): its size as a fraction of the window's, and the
// border around it, in its own pixels. The border is out of the window.
uniform float uScale;
uniform float uBorder;
// How far the camera zooms in, in logical pixels (Camera.focalLength): a
// point s units to the side for each unit ahead lands uFocalLength * s pixels
// from uTargetPixel.
uniform float uFocalLength;
// The camera's position.
uniform vec3 uCamera;
// The camera's directions, each of length 1: where it looks, its right and
// its up.
uniform vec3 uForward;
uniform vec3 uRight;
uniform vec3 uUp;
// The hole: the radius of its shadow, of the sphere it bends rays in, and
// of the disk's outer edge. The disk turns by uDiskAngle.
uniform float uHoleShadowRadius;
uniform float uLensingRadius;
uniform float uDiskOuter;
uniform float uDiskAngle;
// The hole's look (HoleLook in lib/scene/looks.dart).
uniform float uPull;
uniform vec3 uDiskInnerColor;
uniform vec3 uDiskOuterColor;
uniform float uDiskBrightness;
uniform vec3 uJetColor;
uniform float uJetBrightness;
uniform float uJetLength;
uniform vec3 uGlowColor;
uniform vec3 uTint;
uniform vec3 uContrast;
// The light that the hole gives the bodies; the light that reaches every
// side of them; and how much brighter that is at their edges.
uniform vec3 uLight;
uniform vec3 uAmbient;
uniform float uRim;
// Each body's sphere: its center in xyz and its radius in w. A radius of 0
// leaves the slot empty. The radius is the planet's own; its rings and glow
// go farther.
uniform vec4 uBody0;
uniform vec4 uBody1;
uniform vec4 uBody2;
uniform vec4 uBody3;
// Each body's spin axis in xyz, of length 1, and the kind of its look in w:
// flatKind, ringedKind or keplerKind.
uniform vec4 uSlot0;
uniform vec4 uSlot1;
uniform vec4 uSlot2;
uniform vec4 uSlot3;
// For each slot, how far its body draws from its center (rings and glow
// included) if that comes into the lensing sphere, else 0.
uniform vec4 uBodiesInLensingRadius;
// Each body's look. What each element holds depends on the kind (see
// shadeBody).
const int lookSize = 11;
uniform vec4 uLook0[lookSize];
uniform vec4 uLook1[lookSize];
uniform vec4 uLook2[lookSize];
uniform vec4 uLook3[lookSize];
// 1 draws every body as a sphere of one color, the first element of its
// look, the hole's shadow in uPlaceholderHole, and black in place of the
// sky and the disk. 0 draws the scene.
uniform float uPlaceholders;
uniform vec3 uPlaceholderHole;

#include "planet_ringed.glsl"
#include "planet_kepler.glsl"

// The disk's pattern and the path table, from hole_textures.frag.
uniform sampler2D uDiskPattern;
uniform sampler2D uPath;
// The sky baked by sky_cache.frag.
uniform sampler2D uSkyCache;

// The sky in direction, blended between the four nearest directions of the
// lattice (see latticePlace in sky.glsl) by the texture's own filtering.
// Clamped half a cell inside the face, so no read crosses a face's edge.
vec3 cachedSky(vec3 direction) {
  int face;
  vec2 place = clamp(
    latticePlace(direction, face),
    0.5,
    uSkyCells - 0.5
  );
  float faceIndex = float(face);
  vec2 corner = vec2(mod(faceIndex, 3.0), floor(faceIndex / 3.0)) * uSkyCells;
  vec3 stored =
    texture(uSkyCache, (corner + place) / (uSkyCells * vec2(3.0, 2.0))).rgb;
  return stored * stored * 2.0;
}

// The shader's output: this pixel's color, which main() sets. Red, green,
// blue and alpha (opacity), each from 0 to 1.
out vec4 fragColor;

const float flatKind = 0.0;
const float ringedKind = 1.0;
const float keplerKind = 2.0;

// The element of a ringed look that holds the ring layout.
const int ringLayoutElement = 9;

// What distanceToSphere returns when the ray misses: farther than anything
// in the scene, so any hit is nearer.
const float noHit = 1e9;

// Where the line from origin along direction, which has length 1, is
// inside the sphere with center and radius: the distances along it to where
// it goes in and out, which can be behind origin. Both are noHit if the
// line misses the sphere.
vec2 sphereSpan(vec3 origin, vec3 direction, vec3 center, float radius) {
  // How far along the line it comes nearest the sphere's center.
  vec3 toCenter = center - origin;
  float alongToNearest = dot(toCenter, direction);
  // How near it comes, squared. The origin, the center and that nearest
  // point form a right-angled triangle, so this is Pythagoras.
  float nearestSquared =
    dot(toCenter, toCenter) - alongToNearest * alongToNearest;
  // The line is inside the sphere for the same length either side of its
  // nearest point: half the chord it cuts through the sphere, Pythagoras
  // again. If it passes farther from the center than the radius, this is
  // negative and the line misses.
  float halfChordSquared = radius * radius - nearestSquared;
  if (halfChordSquared < 0.0) return vec2(noHit);
  float halfChord = sqrt(halfChordSquared);
  return vec2(alongToNearest - halfChord, alongToNearest + halfChord);
}

// How far the ray from origin along direction, which has length 1, travels
// before it enters sphere, or noHit if it misses the sphere or enters it
// behind origin.
float distanceToSphere(vec3 origin, vec3 direction, vec4 sphere) {
  if (sphere.w <= 0.0) return noHit;
  float entry = sphereSpan(origin, direction, sphere.xyz, sphere.w).x;
  return entry > 0.0 ? entry : noHit;
}

// How far the ray from origin along direction travels before it meets the
// body, or noHit. For a ringed body, the rings' whole width counts, gaps
// included, but not the space between the planet and its rings.
// ringLayout is in planet radii (RingedLook.ringLayout).
float distanceToBody(
  vec3 origin,
  vec3 direction,
  vec4 body,
  vec4 slot,
  vec4 ringLayout
) {
  float kind = slot.w;
  if (uPlaceholders > 0.5 || kind == flatKind) {
    return distanceToSphere(origin, direction, body);
  }
  if (kind == keplerKind) {
    return distanceToSphere(
      origin,
      direction,
      vec4(body.xyz, body.w * keplerGlowRadius)
    );
  }

  float halfWidth = ringHalfWidth(ringLayout);
  float reach = max(ringLayout.x + halfWidth, 1.0);
  vec3 toCenter = body.xyz - origin;
  bool isInside = length(toCenter) < body.w * reach;
  if (
    !isInside &&
    distanceToSphere(origin, direction, vec4(body.xyz, body.w * reach)) ==
      noHit
  ) {
    return noHit;
  }

  float planet = distanceToSphere(origin, direction, body);
  vec3 axis = slot.xyz;
  float across = dot(direction, axis);
  if (abs(across) < 1e-6) return planet;
  float toPlane = dot(toCenter, axis) / across;
  if (toPlane <= 0.0) return planet;
  float ringRadius = length(origin + direction * toPlane - body.xyz) / body.w;
  bool isInRings =
    halfWidth > 0.0 && abs(ringRadius - ringLayout.x) <= halfWidth;
  return isInRings ? min(planet, toPlane) : planet;
}

// The direction of the ray from the camera through pixel, of length 1.
vec3 rayThrough(vec2 pixel) {
  // The slope of the ray through this pixel (see uFocalLength).
  vec2 slope = (pixel - uTargetPixel) / uFocalLength;
  // Pixel y counts down, so the direction subtracts uUp.
  return normalize(uForward + slope.x * uRight - slope.y * uUp);
}

// A body's own space, which the planets are shaded in: its center at 0, its
// axis along y, and scale units for each world unit.
struct BodySpace {
  vec3 center;
  vec3 x;
  vec3 y;
  vec3 z;
  float scale;
};

BodySpace bodySpace(vec4 body, vec3 axis, float unitsPerRadius) {
  vec3 other = abs(axis.y) < 0.9 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0);
  vec3 x = normalize(cross(axis, other));
  return BodySpace(body.xyz, x, axis, cross(x, axis), unitsPerRadius / body.w);
}

vec3 toBodyDirection(BodySpace space, vec3 direction) {
  return vec3(
    dot(direction, space.x),
    dot(direction, space.y),
    dot(direction, space.z)
  );
}

vec3 toBodyPoint(BodySpace space, vec3 point) {
  return toBodyDirection(space, point - space.center);
}

// The premultiplied color and the coverage of the body in slot at pixel,
// along the ray from origin in direction. maxDistance is where that ray
// meets the body behind it, or noHit.
vec4 shadeBody(
  int slot,
  vec2 pixel,
  vec3 origin,
  vec3 direction,
  float maxDistance
) {
  vec4 body;
  vec4 info;
  vec4 look[lookSize];
  for (int i = 0; i < lookSize; i++) {
    if (slot == 0) {
      look[i] = uLook0[i];
    } else if (slot == 1) {
      look[i] = uLook1[i];
    } else if (slot == 2) {
      look[i] = uLook2[i];
    } else {
      look[i] = uLook3[i];
    }
  }
  if (slot == 0) {
    body = uBody0;
    info = uSlot0;
  } else if (slot == 1) {
    body = uBody1;
    info = uSlot1;
  } else if (slot == 2) {
    body = uBody2;
    info = uSlot2;
  } else {
    body = uBody3;
    info = uSlot3;
  }

  float kind = info.w;
  if (uPlaceholders > 0.5 || kind == flatKind) return vec4(look[0].rgb, 1.0);

  // The elements of each kind of look, as SceneShader sets them. Arrays
  // cannot be function arguments here.
  if (kind == keplerKind) {
    Kepler kepler = Kepler(
      look[0].rgb,
      look[1].rgb,
      look[2].rgb,
      look[3].rgb,
      look[4].rgb,
      look[0].w,
      look[1].w,
      look[5].rgb,
      look[6].rgb,
      look[7].rgb,
      look[8].xy,
      look[8].z,
      look[8].w
    );
    BodySpace space = bodySpace(body, info.xyz, 1.0);
    return keplerRay(
      kepler,
      toBodyPoint(space, origin) * space.scale,
      toBodyDirection(space, direction),
      toBodyPoint(space, vec3(0.0)) * space.scale
    );
  }

  BodySpace space = bodySpace(body, info.xyz, ringedRadius);
  Ringed ringed = Ringed(
    look[0].rgb,
    look[1].rgb,
    look[2].rgb,
    look[3].rgb,
    look[4],
    look[5].rgb,
    look[6].rgb,
    look[7].rgb,
    look[8].rgb,
    look[ringLayoutElement] * ringedRadius,
    look[10],
    look[0].w
  );
  vec3 bodyOrigin = toBodyPoint(space, origin) * space.scale;
  vec3 bodyDirection = toBodyDirection(space, direction);
  vec3 light = toBodyPoint(space, vec3(0.0)) * space.scale;
  float maxBodyDistance = maxDistance * space.scale;
  bool isSmooth = isRingedSmooth(
    ringed,
    bodyOrigin,
    bodyDirection,
    1.0 / (uFocalLength * uPixelRatio)
  );
  // Four samples in a rotated grid, in drawn pixels. In a loop, so the
  // shading is compiled once, and neighboring pixels, which a GPU runs in
  // lockstep, run the same code. Each sample's ray turns from direction as
  // the camera's ray through it turns from the pixel's.
  float samples = isSmooth ? 1.0 : 4.0;
  vec2 offset1 = vec2(1.0, 3.0) / 8.0 / uPixelRatio;
  vec2 offset2 = vec2(-3.0, 1.0) / 8.0 / uPixelRatio;
  vec3 centerRay = rayThrough(pixel);
  vec3 sampleOrigins[4];
  vec3 sampleDirections[4];
  for (int i = 0; i < 4; i++) {
    vec2 offset = isSmooth
      ? vec2(0.0)
      : i == 0
        ? offset1
        : i == 1
          ? -offset1
          : i == 2
            ? offset2
            : -offset2;
    // Past the hole, origin is where the ray leaves the lensing sphere,
    // and it moves with the turn as a neighboring pixel's would.
    vec3 turn = rayThrough(pixel + offset) - centerRay;
    vec3 sampleOrigin = origin + turn * length(origin - uCamera);
    vec3 sampleDirection = normalize(direction + turn);
    sampleOrigins[i] = toBodyPoint(space, sampleOrigin) * space.scale;
    sampleDirections[i] = toBodyDirection(space, sampleDirection);
  }
  // The rings are shaded once for the pixel, averaged over it, and the
  // samples smooth only the edges of the planet and of what hides the
  // rings.
  vec4 ring = vec4(0.0);
  if (!isSmooth) {
    // How much the ring radius changes over a drawn pixel, measured on
    // the sample rays, as fwidth would. Each pair of opposite samples is
    // sqrt(10) / 4 drawn pixels apart, and the two pairs are at right
    // angles.
    float across1 = ringPlaneRadius(sampleOrigins[0], sampleDirections[0]) -
      ringPlaneRadius(sampleOrigins[1], sampleDirections[1]);
    float across2 = ringPlaneRadius(sampleOrigins[2], sampleDirections[2]) -
      ringPlaneRadius(sampleOrigins[3], sampleDirections[3]);
    float footprint =
      max(length(vec2(across1, across2)) * 4.0 / sqrt(10.0), 1e-4);
    ring = ringsAlong(ringed, bodyOrigin, bodyDirection, light, footprint);
  }
  vec4 c = vec4(0.0);
  for (int i = 0; i < 4; i++) {
    if (float(i) >= samples) break;
    c += ringedRay(
      ringed,
      sampleOrigins[i],
      sampleDirections[i],
      light,
      maxBodyDistance,
      ring
    );
  }
  c /= samples;
  // The color is premultiplied, so a channel below 0 would darken what
  // shows behind the rings.
  return vec4(max(ringedPostProcess(c.rgb), 0.0), c.a);
}


// A body that a ray meets: how far the ray goes before it meets it, and
// the slot (-1 for none).
struct Meeting {
  float entry;
  int slot;
};

// Puts meeting into the nearest two so far.
void takeNearer(Meeting meeting, inout Meeting nearest, inout Meeting next) {
  if (meeting.entry < nearest.entry) {
    next = nearest;
    nearest = meeting;
  } else if (meeting.entry < next.entry) {
    next = meeting;
  }
}

// A body that the ray meets: its slot (-1 for none), the straight piece of
// the ray that meets it (its start and its direction), and the point where
// it meets the body.
struct Hit {
  int slot;
  vec3 origin;
  vec3 direction;
  vec3 point;
};

Hit noBody() {
  return Hit(-1, vec3(0.0), vec3(0.0), vec3(0.0));
}

Hit hitOf(Meeting meeting, vec3 origin, vec3 direction) {
  return Hit(
    meeting.slot,
    origin,
    direction,
    origin + direction * meeting.entry
  );
}

// The body in slot meets the ray from origin along direction within len:
// puts it into the nearest two so far, unless the ray has met it before.
void meetBody(
  int slot,
  vec4 body,
  vec4 slotInfo,
  vec4 ringLayout,
  vec3 origin,
  vec3 direction,
  float len,
  Hit front,
  Hit back,
  inout Meeting nearest,
  inout Meeting next
) {
  if (front.slot == slot || back.slot == slot) return;
  float entry = distanceToBody(origin, direction, body, slotInfo, ringLayout);
  if (entry < len) takeNearer(Meeting(entry, slot), nearest, next);
}

// Adds nearest and next, the bodies that one piece of the ray meets, to
// front and back, the first two bodies on the whole ray. Returns whether it
// set front.
bool keepMeetings(
  Meeting nearest,
  Meeting next,
  vec3 origin,
  vec3 direction,
  inout Hit front,
  inout Hit back
) {
  if (nearest.slot < 0) return false;
  if (front.slot >= 0) {
    back = hitOf(nearest, origin, direction);
    return false;
  }
  front = hitOf(nearest, origin, direction);
  if (next.slot >= 0) back = hitOf(next, origin, direction);
  return true;
}

// Adds the bodies that the straight piece from origin along direction
// meets within len to the first two bodies along the ray, front and back.
// Returns whether it found the front body.
bool findBodies(
  vec3 origin,
  vec3 direction,
  float len,
  inout Hit front,
  inout Hit back
) {
  if (back.slot >= 0) return false;
  Meeting nearest = Meeting(noHit, -1);
  Meeting next = nearest;
  meetBody(0, uBody0, uSlot0, uLook0[ringLayoutElement], origin, direction,
    len, front, back, nearest, next);
  meetBody(1, uBody1, uSlot1, uLook1[ringLayoutElement], origin, direction,
    len, front, back, nearest, next);
  meetBody(2, uBody2, uSlot2, uLook2[ringLayoutElement], origin, direction,
    len, front, back, nearest, next);
  meetBody(3, uBody3, uSlot3, uLook3[ringLayoutElement], origin, direction,
    len, front, back, nearest, next);
  return keepMeetings(nearest, next, origin, direction, front, back);
}

// Whether the piece from a to b can come within reach of the center of
// body: whether its distances from the hole overlap the body's shell.
bool canMeet(vec3 a, vec3 b, vec4 body, float reach) {
  vec3 piece = b - a;
  float t = clamp(-dot(a, piece) / max(dot(piece, piece), 1e-12), 0.0, 1.0);
  float nearest = length(a + piece * t);
  float furthest = max(length(a), length(b));
  float center = length(body.xyz);
  return nearest < center + reach && furthest > center - reach;
}

// As findBodies, for the piece of the bent path from a to b inside the
// lensing sphere, and only for the slots in candidates. Returns where the
// new front body is along the piece, from 0 to 1, or 2 if there is none.
float findBodiesInside(
  vec3 a,
  vec3 b,
  bvec4 candidates,
  inout Hit front,
  inout Hit back
) {
  if (back.slot >= 0) return 2.0;
  vec3 direction = b - a;
  float len = length(direction);
  if (len <= 0.0) return 2.0;
  direction /= len;
  Meeting nearest = Meeting(noHit, -1);
  Meeting next = nearest;
  if (candidates.x && canMeet(a, b, uBody0, uBodiesInLensingRadius.x)) {
    meetBody(0, uBody0, uSlot0, uLook0[ringLayoutElement], a, direction,
      len, front, back, nearest, next);
  }
  if (candidates.y && canMeet(a, b, uBody1, uBodiesInLensingRadius.y)) {
    meetBody(1, uBody1, uSlot1, uLook1[ringLayoutElement], a, direction,
      len, front, back, nearest, next);
  }
  if (candidates.z && canMeet(a, b, uBody2, uBodiesInLensingRadius.z)) {
    meetBody(2, uBody2, uSlot2, uLook2[ringLayoutElement], a, direction,
      len, front, back, nearest, next);
  }
  if (candidates.w && canMeet(a, b, uBody3, uBodiesInLensingRadius.w)) {
    meetBody(3, uBody3, uSlot3, uLook3[ringLayoutElement], a, direction,
      len, front, back, nearest, next);
  }
  if (!keepMeetings(nearest, next, a, direction, front, back)) return 2.0;
  return distance(a, front.point) / len;
}

// asinh(x), which this GLSL lacks.
float inverseSinh(float x) {
  float size = abs(x);
  return sign(x) * log(size + sqrt(size * size + 1.0));
}

// A value of the path table (hole.glsl) at impact parameter share, b over
// the lensing sphere's radius, from 0 to 1.
float pathValue(float share, float row) {
  vec4 texel = texture(uPath, vec2(share, (row + 0.5) / pathRows));
  return texel.r + (texel.g - 0.5) / 255.0;
}

// The light that the march adds for each hole unit of path at r from the
// hole. The march adds light for each step of holeStep at the ray's speed,
// which grows as the ray falls: v^2 / 2 - pull / r stays the same.
float lightPerLength(float r, float sphere) {
  float pull = uPull / holeStep;
  float fall = 1.0 / max(r, holeHorizon) - 1.0 / sphere;
  float speed = sqrt(max(1.0 + 2.0 * pull * fall, 1.0));
  return 1.0 / (holeStep * speed);
}

// The jets' light along the straight piece from a to b, in hole units.
// sphere is the lensing sphere's radius, in hole units.
vec3 jetLight(vec3 a, vec3 b, float sphere) {
  vec3 piece = b - a;
  float len = length(piece);
  if (len <= 0.0) return vec3(0.0);
  vec3 direction = piece / len;
  float aa = dot(direction.xz, direction.xz);
  float bb = 2.0 * dot(a.xz, direction.xz);
  // Most of the light comes from the piece's point nearest the jets' axis,
  // so the jets' width and fade are taken there.
  float alongToAxis = aa < 1e-6 ? 0.5 * len : clamp(-bb / (2.0 * aa), 0.0, len);
  vec3 nearAxis = a + direction * alongToAxis;
  float r = length(nearAxis);
  float jetPulse = sin(uDiskAngle * 20.0) * 0.5 + 0.5;
  float spread = abs(nearAxis.y * nearAxis.y * (0.00625 + jetPulse * 0.0125));
  // The integral of 1 / sqrt(d^2 + spread^2) along the piece, where d is
  // the distance from the jets' axis, in closed form.
  float cc = dot(a.xz, a.xz) + spread * spread + 4e-4;
  float jets;
  if (aa < 1e-6) {
    jets = len * inversesqrt(cc);
  } else {
    float scale = inversesqrt(max(4.0 * aa * cc - bb * bb, 1e-12));
    jets = (inverseSinh((2.0 * aa * len + bb) * scale) -
      inverseSinh(bb * scale)) * inversesqrt(aa);
  }
  float jetLength = uJetLength / holeUnit(uDiskOuter);
  float jetFade = smoothstep(0.0, 1.0, r - holeHorizon) *
    smoothstep(jetLength, 0.5 * jetLength, r);
  return uJetColor *
    (jets * uJetBrightness * jetFade * lightPerLength(r, sphere));
}

// The hole's light along the straight piece from a to b, in hole units:
// the disk's, and with withJets the jets'. sphere is the lensing sphere's
// radius, in hole units.
vec3 lightAlong(
  vec3 a,
  vec3 b,
  float sphere,
  bool withJets
) {
  vec3 light = vec3(0.0);
  vec3 piece = b - a;
  float len = length(piece);
  if (len <= 0.0) return light;
  float perLength = lightPerLength(length((a + b) * 0.5), sphere);
  if (withJets) light += jetLight(a, b, sphere);

  // The disk: the part of the piece inside the disk's slab, with the
  // torus's density and the pattern averaged over four points.
  float inside0 = 0.0;
  float inside1 = 1.0;
  if (abs(piece.y) > 1e-6) {
    float t1 = (-diskHalfThickness - a.y) / piece.y;
    float t2 = (diskHalfThickness - a.y) / piece.y;
    inside0 = max(0.0, min(t1, t2));
    inside1 = min(1.0, max(t1, t2));
  } else if (abs(a.y) > diskHalfThickness) {
    inside1 = 0.0;
  }
  if (inside1 > inside0) {
    vec3 disk = vec3(0.0);
    for (int k = 0; k < 4; k++) {
      vec3 q = a + piece * mix(inside0, inside1, (float(k) + 0.5) / 4.0);
      float across = length(q.xz);
      vec2 torus = vec2(across - torusCenter, q.y * diskFlattening);
      float density = smoothstep(0.0, 1.5, torusMinor - length(torus));
      float fromHorizon = length(q) - holeHorizon;
      float angle = uDiskAngle - dot(q.xz, q.xz) * 0.6;
      float cosAngle = cos(angle);
      float sinAngle = sin(angle);
      vec2 patternPoint = vec2(
        -q.x * cosAngle + q.z * sinAngle,
        -q.x * sinAngle - q.z * cosAngle
      ) * 0.70710678118654752 * 0.5 + 0.5;
      float pattern = texture(uDiskPattern, patternPoint).x * 2.0;
      disk += max(
        vec3(0.0),
        mix(uDiskInnerColor, uDiskOuterColor, fromHorizon * fromHorizon) *
          pattern * density
      );
    }
    light += disk *
      (uDiskBrightness * perLength * len * (inside1 - inside0) / 4.0);
  }
  return light;
}

// The pieces of a straight ray that straightLight gathers the jets in.
const int jetPieces = 2;

// The hole's light along the straight ray from origin along direction,
// from 0 to len, outside the lensing sphere. unit is world units per hole
// unit.
vec3 straightLight(
  vec3 origin,
  vec3 direction,
  float len,
  float unit,
  float sphere
) {
  vec3 light = vec3(0.0);
  // Only the part of the ray within the disk's reach.
  vec2 span = sphereSpan(origin, direction, vec3(0.0), uDiskOuter);
  float start = max(span.x, 0.0);
  float end = min(span.y, len);
  if (end > start) {
    light += lightAlong(
      (origin + direction * start) / unit,
      (origin + direction * end) / unit,
      sphere,
      false
    );
  }
  // The jets, in pieces, because their width and fade change along them.
  span = sphereSpan(origin, direction, vec3(0.0), uJetLength);
  start = max(span.x, 0.0);
  end = min(span.y, len);
  if (end > start) {
    vec3 a = (origin + direction * start) / unit;
    vec3 step = direction * ((end - start) / unit / float(jetPieces));
    for (int k = 0; k < jetPieces; k++) {
      light += jetLight(a, a + step, sphere);
      a += step;
    }
  }
  return light;
}

// nethe550's contrast curve and tint, for the hole's own light.
vec3 grade(vec3 c) {
  return pow(max(c, vec3(0.0)), uContrast) * uTint;
}

// The straight piece of the ray from origin along direction, of length len:
// adds the bodies on it to front and back, and the hole's light on it to
// emission, or to frontEmission for the light in front of a new front body.
void straightPiece(
  vec3 origin,
  vec3 direction,
  float len,
  float unit,
  float sphere,
  inout Hit front,
  inout Hit back,
  inout vec3 emission,
  inout vec3 frontEmission
) {
  bool isNewFront = findBodies(origin, direction, len, front, back);
  if (uPlaceholders > 0.5) return;
  float cut = isNewFront ? distance(origin, front.point) : len;
  emission += straightLight(origin, direction, cut, unit, sphere);
  if (isNewFront) {
    frontEmission = emission;
    emission = straightLight(origin + direction * cut, direction, len - cut,
      unit, sphere);
  }
}

// Follows the ray from the camera along direction past the hole. Adds the
// bodies it meets to front and back, and the hole's light to emission
// (behind the front body) or frontEmission (in front of it). Sets
// skyDirection to where the ray ends, and returns how much of the sky
// shows there: 0 if the hole catches the ray.
float traceRay(
  vec3 direction,
  inout Hit front,
  inout Hit back,
  inout vec3 emission,
  inout vec3 frontEmission,
  out vec3 skyDirection
) {
  float unit = holeUnit(uDiskOuter);
  float sphere = uLensingRadius / unit;
  skyDirection = direction;

  // The straight ray's nearest point to the hole, and its distance b.
  float along = -dot(uCamera, direction);
  vec3 nearest = uCamera + along * direction;
  float b = length(nearest);
  bool isCaught = along > 0.0 && b < uHoleShadowRadius;
  bool isBent = along > 0.0 && b < uLensingRadius &&
    dot(uCamera, uCamera) > uLensingRadius * uLensingRadius;
  if (!isBent) {
    float len = isCaught
      ? along - sqrt(uHoleShadowRadius * uHoleShadowRadius - b * b)
      : noHit;
    straightPiece(uCamera, direction, len, unit, sphere, front, back,
      emission, frontEmission);
    return isCaught ? 0.0 : 1.0;
  }

  // To the lensing sphere.
  float entry = along - sqrt(uLensingRadius * uLensingRadius - b * b);
  straightPiece(uCamera, direction, entry, unit, sphere,
    front, back, emission, frontEmission);

  // Inside it, along the path. The hole pulls the ray only toward itself,
  // so the path stays in the plane through the hole and the straight ray.
  // Only the bodies in the lensing radius and near that plane can meet it.
  vec3 across = b > 1e-6 ? nearest / b : uUp;
  vec3 normal = cross(direction, across);
  vec4 reach = uBodiesInLensingRadius;
  bvec4 candidates = bvec4(
    reach.x > 0.0 && abs(dot(uBody0.xyz, normal)) < reach.x,
    reach.y > 0.0 && abs(dot(uBody1.xyz, normal)) < reach.y,
    reach.z > 0.0 && abs(dot(uBody2.xyz, normal)) < reach.z,
    reach.w > 0.0 && abs(dot(uBody3.xyz, normal)) < reach.w
  );
  bool hasCandidates = any(candidates);
  float share = b / uLensingRadius;
  vec3 point = (uCamera + direction * entry) / unit;
  for (int k = 0; k < pathPoints; k++) {
    vec2 xy = (vec2(
      pathValue(share, float(k)),
      pathValue(share, float(k + pathPoints))
    ) * 2.0 - 1.0) * sphere;
    vec3 next = xy.x * direction + xy.y * across;
    // The points after the path's end are all its last point.
    if (distance(next, point) < 1e-4) break;
    float cut = hasCandidates
      ? findBodiesInside(point * unit, next * unit, candidates, front, back)
      : 2.0;
    if (uPlaceholders < 0.5) {
      if (cut <= 1.0) {
        // The light in front of the new front body, and behind it.
        vec3 meeting = mix(point, next, cut);
        frontEmission = emission + lightAlong(point, meeting, sphere, true);
        emission = lightAlong(meeting, next, sphere, true);
      } else {
        emission += lightAlong(point, next, sphere, true);
      }
    }
    point = next;
  }
  if (isCaught) return 0.0;

  // Out of the sphere, turned toward the hole.
  float turn = pathValue(share, turnRow) * turnLimit;
  skyDirection = cos(turn) * direction - sin(turn) * across;
  if (uPlaceholders < 0.5) {
    emission += uGlowColor * pathValue(share, glowRow) * glowLimit;
  }
  straightPiece(point * unit, skyDirection, noHit, unit, sphere,
    front, back, emission, frontEmission);
  return 1.0;
}

void main() {
  vec2 pixel = (FlutterFragCoord().xy - uBorder) / uScale;
  vec3 direction = rayThrough(pixel);
  Hit front = noBody();
  Hit back = noBody();
  vec3 emission = vec3(0.0);
  vec3 frontEmission = vec3(0.0);
  vec3 skyDirection;
  float skyShare = traceRay(
    direction,
    front,
    back,
    emission,
    frontEmission,
    skyDirection
  );

  // What shows behind the bodies, and the light in front of the front body.
  vec3 background;
  vec3 frontLight = vec3(0.0);
  if (uPlaceholders > 0.5) {
    background = skyShare > 0.0 ? vec3(0.0) : uPlaceholderHole;
  } else {
    background = cachedSky(skyDirection) * skyShare;
    if (dot(emission, emission) > 0.0) background += grade(emission);
    if (front.slot >= 0 && dot(frontEmission, frontEmission) > 0.0) {
      frontLight = grade(frontEmission);
    }
  }

  // The front body, then the back one where the front lets it show. The
  // back body hides a ringed planet behind its rings. One call of
  // shadeBody, so the shading is compiled once.
  vec4 body = vec4(0.0);
  for (int layer = 0; layer < 2; layer++) {
    Hit hit = layer == 0 ? front : back;
    if (hit.slot < 0 || body.a >= 1.0) break;
    body += shadeBody(
      hit.slot,
      pixel,
      hit.origin,
      hit.direction,
      layer == 0 && back.slot >= 0 ? length(back.point - front.origin) : noHit
    ) * (1.0 - body.a);
  }
  fragColor = vec4(frontLight + body.rgb + background * (1.0 - body.a), 1.0);
}
