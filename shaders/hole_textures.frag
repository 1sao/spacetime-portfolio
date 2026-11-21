#version 460 core
#include <flutter/runtime_effect.glsl>
#include "hole.glsl"
#include "hole_disc.glsl"

// The hole's textures, baked once at load by lib/scene/hole_textures.dart:
// uKind 0 the disc's pattern, uKind 1 the path table (see hole.glsl).
// "Black Hole" by nethe550 (https://www.shadertoy.com/view/tXsGR2), MIT
// licence.

uniform vec2 uResolution;
uniform float uKind;
// The radius of the lensing sphere and of the disc's outer edge, in world
// units.
uniform float uLensingRadius;
uniform float uDiscOuter;
// How strongly the hole pulls: the change of the ray's direction at 1 hole
// unit from the hole, for each step.
uniform float uPull;

out vec4 fragColor;

// x in [0, 1] as two 8-bit channels, a coarse value and the residual, so
// that both filter linearly and still decode to the filtered x.
vec2 split16(float x) {
  float c = floor(x * 255.0 + 0.5) / 255.0;
  return vec2(c, (x - c) * 255.0 + 0.5);
}

vec4 encode(float x) {
  return vec4(split16(clamp(x, 0.0, 1.0)), 0.0, 1.0);
}

void main() {
  vec2 frag = FlutterFragCoord().xy;
  if (uKind < 0.5) {
    // The pattern reaches about 1.2, so the texture holds half of it.
    fragColor = vec4(discPattern(frag / uResolution) * 0.5, 0.0, 0.0, 1.0);
    return;
  }

  float sphere = uLensingRadius / holeUnit(uDiscOuter);
  // A larger sphere has longer paths, so its points are further apart.
  float cutLength = max(pathCutLength, sphere / 3.0);
  float row = floor(frag.y);
  float b = frag.x / pathColumns * sphere;
  // The point this texel holds: the march stops at it.
  float target = mod(row, float(pathPoints)) + 1.0;
  bool isPoint = row < turnRow;
  if (!isPoint) target = 1e9;

  vec2 point = vec2(-sqrt(sphere * sphere - b * b), b);
  vec2 velocity = vec2(1.0, 0.0);
  // The ray slows as it nears the hole, so it never quite reaches it.
  float speedScale = 1.0;
  float swept = 0.0;
  float gone = 0.0;
  float cuts = 0.0;
  float cutSwept = 0.0;
  float cutGone = 0.0;
  float turn = 0.0;
  float glow = 0.0;
  for (int i = 0; i < 2000; i++) {
    vec2 next = point + velocity * holeStep * speedScale;
    float stepLength = length(next - point);
    // The angle the step sweeps round the hole, clockwise.
    float sweep = atan(point.y * next.x - point.x * next.y, dot(point, next));
    // The share of the step to the next cut.
    float share = min(
      (cutSwept + pathCutSweep - swept) / max(sweep, 1e-9),
      (cutGone + cutLength - gone) / max(stepLength, 1e-9)
    );
    if (share <= 1.0) {
      cuts += 1.0;
      cutSwept = swept + sweep * share;
      cutGone = gone + stepLength * share;
      if (cuts >= target) {
        point = mix(point, next, share);
        break;
      }
    }
    point = next;
    swept += sweep;
    gone += stepLength;

    float r2 = dot(point, point);
    float r = sqrt(r2);
    float pull = pullShare(r, sphere);
    vec2 before = velocity;
    velocity -= point / (r * r2) * uPull * pull;
    turn += atan(
      before.y * velocity.x - before.x * velocity.y,
      dot(before, velocity)
    );
    glow += 0.00125 / (r2 * r2) * speedScale * speedScale * speedScale * pull;
    speedScale = smoothstep(0.0, 2.0 / 3.0, r - holeHorizon);
    if (speedScale <= 0.0) break;
    if (r > sphere && dot(point, velocity) > 0.0) break;
  }

  if (isPoint) {
    // x in the first rows, y in the next.
    float value = row < float(pathPoints) ? point.x : point.y;
    fragColor = encode(value / sphere * 0.5 + 0.5);
  } else if (row < glowRow) {
    fragColor = encode(turn / turnLimit);
  } else {
    fragColor = encode(glow / glowLimit);
  }
}
