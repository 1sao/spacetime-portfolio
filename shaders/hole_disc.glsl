// The pattern of the hole's disc, from "Black Hole" by nethe550
// (https://www.shadertoy.com/view/tXsGR2), MIT licence. Its simplex noise
// is Ian McEwan's (Ashima Arts, https://github.com/ashima/webgl-noise, MIT
// licence), by way of https://github.com/hughsk/glsl-noise.
// hole_textures.frag bakes it into a texture.

const float ONE_OVER_289 = 1.0 / 289.0;
const float ONE_SEVENTH = 1.0 / 7.0;
const vec2 C = vec2(1.0 / 6.0, 1.0 / 3.0);
const vec4 D = vec4(0.0, 0.5, 1.0, 2.0);

vec3 mod289(vec3 x) { return x - floor(x * ONE_OVER_289) * 289.0; }
vec4 mod289(vec4 x) { return x - floor(x * ONE_OVER_289) * 289.0; }
vec4 permute(vec4 x) { return mod289(((x * 34.0) + 1.0) * x); }
vec4 taylorInvSqrt(vec4 r) { return 1.79284291400159 - 0.85373472095314 * r; }

float simplex(vec3 p) {
  vec3 i = floor(p + dot(p, C.yyy));
  vec3 x0 = p - i + dot(i, C.xxx);
  vec3 g = step(x0.yzx, x0.xyz);
  vec3 l = 1.0 - g;
  vec3 i1 = min(g.xyz, l.zxy);
  vec3 i2 = max(g.xyz, l.zxy);
  vec3 x1 = x0 - i1 + C.xxx;
  vec3 x2 = x0 - i2 + C.yyy;
  vec3 x3 = x0 - D.yyy;
  i = mod289(i);
  vec4 perm = permute(permute(permute(
      i.z + vec4(0.0, i1.z, i2.z, 1.0)) +
      i.y + vec4(0.0, i1.y, i2.y, 1.0)) +
      i.x + vec4(0.0, i1.x, i2.x, 1.0));
  vec3 ns = ONE_SEVENTH * D.wyz - D.xzx;
  vec4 j = perm - 49.0 * floor(perm * ns.z * ns.z);
  vec4 x_ = floor(j * ns.z);
  vec4 y_ = floor(j - 7.0 * x_);
  vec4 x = x_ * ns.x + ns.yyyy;
  vec4 y = y_ * ns.x + ns.yyyy;
  vec4 h = 1.0 - abs(x) - abs(y);
  vec4 b0 = vec4(x.xy, y.xy);
  vec4 b1 = vec4(x.zw, y.zw);
  vec4 s0 = floor(b0) * 2.0 + 1.0;
  vec4 s1 = floor(b1) * 2.0 + 1.0;
  vec4 sh = -step(h, vec4(0.0));
  vec4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
  vec4 a1 = b1.xzyw + s1.xzyw * sh.zzww;
  vec3 p0 = vec3(a0.xy, h.x);
  vec3 p1 = vec3(a0.zw, h.y);
  vec3 p2 = vec3(a1.xy, h.z);
  vec3 p3 = vec3(a1.zw, h.w);
  vec4 norm = taylorInvSqrt(
    vec4(dot(p0, p0), dot(p1, p1), dot(p2, p2), dot(p3, p3))
  );
  p0 *= norm.x;
  p1 *= norm.y;
  p2 *= norm.z;
  p3 *= norm.w;
  vec4 m = max(
    0.6 - vec4(dot(x0, x0), dot(x1, x1), dot(x2, x2), dot(x3, x3)),
    0.0
  );
  m *= m;
  return 42.0 *
    dot(m * m, vec4(dot(p0, x0), dot(p1, x1), dot(p2, x2), dot(p3, x3)));
}

// Two octaves of nethe550's fbm.
float fbm2(vec3 p) {
  const float s = 0.479425538604203; // sin(0.5)
  const float c = 0.877582561890373; // cos(0.5)
  const mat3 rot = mat3(c, 0.0, s, 0.0, 1.0, 0.0, -s, 0.0, c);
  float value = simplex(p);
  p = rot * (p * vec3(3.5, 4.125, 3.1)) + vec3(100.0);
  return value + simplex(p) * 0.5;
}

// The disc's brightness at uv, a point on the disc from 0 to 1 across.
float discPattern(vec2 uv) {
  return max(0.0, fbm2(vec3(uv * 10.0, 0.0)) * 0.5 + 0.5);
}
