#version 460 core
// The hash functions: "Hash without Sine" by Dave Hoskins
// https://www.shadertoy.com/view/4djSRW
// License: MIT. The full licence text is in LICENSES/hash-without-sine.txt.

// Textures for planet_kepler.glsl, baked once at load by
// lib/scene/kepler_textures.dart. Each one tiles, and has a border of one
// texel copied from the opposite edge, so that bilinear filtering wraps
// (Flutter's samplers clamp).
//   uKind 0: the surface, 1024 texels. R: streaks, for the clouds. G:
//            rounded blobs with dark gaps between, for the land. B:
//            slow changes that set how much land is dry and how much the
//            clouds swirl.
//   uKind 1: noise in each channel, 64 texels.
//   uKind 2: dark patches for the land in its red channel, 512 texels.
// uResolution is the texels across, with the border.

#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;
uniform float uKind;

out vec4 fragColor;

// Dave Hoskins, "Hash without Sine".
float hash12(vec2 p) {
  vec3 p3 = fract(vec3(p.xyx) * .1031);
  p3 += dot(p3, p3.yzx + 33.33);
  return fract((p3.x + p3.y) * p3.z);
}

vec4 hash42(vec2 p) {
  vec4 p4 = fract(vec4(p.xyxy) * vec4(.1031, .1030, .0973, .1099));
  p4 += dot(p4, p4.wzxy + 33.33);
  return fract((p4.xxyz + p4.yzzw) * p4.zywx);
}

// Gradient noise that repeats every `per` cells, about -0.7..0.7.
float gnoise(vec2 p, vec2 per, float seed) {
  vec2 i = floor(p);
  vec2 f = p - i;
  vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
  vec2 i0 = mod(i, per) + seed;
  vec2 i1 = mod(i + 1.0, per) + seed;
  float ga = hash12(i0) * 6.2831853;
  float gb = hash12(vec2(i1.x, i0.y)) * 6.2831853;
  float gc = hash12(vec2(i0.x, i1.y)) * 6.2831853;
  float gd = hash12(i1) * 6.2831853;
  float a = dot(vec2(cos(ga), sin(ga)), f);
  float b = dot(vec2(cos(gb), sin(gb)), f - vec2(1.0, 0.0));
  float c = dot(vec2(cos(gc), sin(gc)), f - vec2(0.0, 1.0));
  float d = dot(vec2(cos(gd), sin(gd)), f - 1.0);
  return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p, vec2 per, float seed) {
  float s = 0.0;
  float amp = 0.5;
  for (int k = 0; k < 7; k++) {
    s += amp * gnoise(p, per, seed + float(k) * 17.0);
    p *= 2.0;
    per *= 2.0;
    amp *= 0.5;
  }
  return s;
}

// The fbm above has a standard deviation of about 0.12. Each texture below
// maps it to the range of values that planet_kepler.glsl is tuned for.

// Streaks along x, warped, for the clouds: median 0.28, quartiles 0.15 and
// 0.45.
float clouds(vec2 uv) {
  vec2 per = vec2(3.0, 12.0);
  vec2 p = uv * per;
  vec2 w = vec2(fbm(p, per, 1.0), fbm(p + 5.2, per, 2.0));
  float v = fbm(p + w * 1.5, per, 3.0);
  return clamp(0.28 + 1.83 * v, 0.0, 1.0);
}

// Rounded blobs with dark gaps between, for the land: median 0.15, above
// 0.25 (land) on 30 % of the texture.
float land(vec2 uv) {
  const float cells = 6.0;
  vec2 p = uv * cells;
  p += 0.6 * vec2(
    fbm(uv * 4.0, vec2(4.0), 7.0),
    fbm(uv * 4.0 + 3.1, vec2(4.0), 8.0)
  );
  vec2 i = floor(p);
  vec2 f = p - i;
  float d1 = 8.0;
  float d2 = 8.0;
  vec2 id = vec2(0.0);
  for (int y = -1; y <= 1; y++) {
    for (int x = -1; x <= 1; x++) {
      vec2 o = vec2(float(x), float(y));
      vec2 c = mod(i + o, cells);
      vec2 pt = o + 0.15 + 0.7 * vec2(hash12(c + 11.0), hash12(c + 23.0)) - f;
      float d = dot(pt, pt);
      if (d < d1) {
        d2 = d1;
        d1 = d;
        id = c;
      } else if (d < d2) {
        d2 = d;
      }
    }
  }
  // Round, not the cell's polygon: near its point, and clear of the next.
  float stone = (1.0 - smoothstep(0.3, 0.62, sqrt(d1))) *
    smoothstep(0.02, 0.25, sqrt(d2) - sqrt(d1));
  float bright = hash12(id + 37.0);
  float z = mix(0.08, 0.06 + 0.72 * pow(bright, 1.5), stone);
  z += 0.2 * fbm(uv * 16.0, vec2(16.0), 9.0);
  return clamp(z, 0.0, 1.0);
}

// Dark patches: red median 0.30, quartiles 0.23 and 0.40; green and blue
// 0.73 and 0.52 of it.
vec3 rust(vec2 uv) {
  float n = fbm(uv * 8.0, vec2(8.0), 13.0);
  float r = clamp(0.3 * exp(3.1 * n), 0.0, 1.0);
  return vec3(r, r * 0.73, r * 0.52);
}

void main() {
  float n = uResolution.x - 2.0;
  vec2 j = mod(floor(FlutterFragCoord().xy) - 1.0, n);
  vec2 uv = (j + 0.5) / n;
  if (uKind == 0.0) {
    float blurry =
      clamp(0.28 + 0.25 * fbm(uv * 4.0, vec2(4.0), 21.0), 0.0, 1.0);
    fragColor = vec4(clouds(uv), land(uv), blurry, 1.0);
  } else if (uKind == 1.0) {
    fragColor = vec4(hash42(j + 0.5).rgb, 1.0);
  } else {
    fragColor = vec4(rust(uv), 1.0);
  }
}
