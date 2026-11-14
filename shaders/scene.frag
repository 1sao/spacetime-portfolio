#version 460 core
#include <flutter/runtime_effect.glsl>
#include "sky.glsl"

// The scene: the central body and up to four bodies, each a sphere drawn as
// a flat disc in one colour, over the sky (sky.glsl).
//
// A fragment shader runs once for every pixel and returns that pixel's
// colour. This one casts a ray from the camera through the pixel, finds the
// nearest sphere the ray hits, and gives the pixel that sphere's colour, or
// the sky's colour if the ray hits no sphere.
//
// lib/scene/scene_shader.dart sets the uniforms by name. Positions and
// lengths are in world units, colours are red, green and blue from 0 to 1.

// The size of the area drawn, in pixels.
uniform vec2 uSize;
// Pixels per unit of slope off the view axis. A ray's slope is how far it
// strays from the axis for each unit it travels forward: the tangent of its
// angle off the axis. A point seen at slope s is drawn uFocal * s pixels
// from the middle of the area.
uniform float uFocal;
// The camera's position.
uniform vec3 uCamera;
// The camera's directions, each of length 1: where it looks, its right and
// its up.
uniform vec3 uForward;
uniform vec3 uRight;
uniform vec3 uUp;
// The central body, a sphere at the origin.
uniform float uCentralBodyRadius;
uniform vec3 uCentralBodyColour;
// Each body's sphere: its centre in xyz and its radius in w. A radius of 0
// leaves the slot empty. Flutter's shaders can't use arrays, so each body
// has its own uniform.
uniform vec4 uBody0;
uniform vec4 uBody1;
uniform vec4 uBody2;
uniform vec4 uBody3;
// Each body's colour.
uniform vec3 uColour0;
uniform vec3 uColour1;
uniform vec3 uColour2;
uniform vec3 uColour3;
// 1 draws black in place of the sky, for the render test, which finds each
// body by its colour. 0 draws the sky.
uniform float uPlaceholders;

// The shader's output: this pixel's colour, which main() sets. Red, green,
// blue and alpha (opacity), each from 0 to 1.
out vec4 fragColor;

// What distanceToSphere returns when the ray misses: further than anything
// in the scene, so any hit is nearer.
const float noHit = 1e9;

// How far the ray from the camera along direction, which has length 1,
// travels before it enters sphere, or noHit if it misses the sphere or
// enters it behind the camera.
float distanceToSphere(vec3 direction, vec4 sphere) {
  vec3 centre = sphere.xyz;
  float radius = sphere.w;
  if (radius <= 0.0) return noHit;

  // How far along the ray it comes nearest the sphere's centre.
  vec3 toCentre = centre - uCamera;
  float alongToNearest = dot(toCentre, direction);
  // How near it comes, squared. The camera, the centre and that nearest
  // point form a right-angled triangle, so this is Pythagoras.
  float nearestSquared =
    dot(toCentre, toCentre) - alongToNearest * alongToNearest;
  // The ray is inside the sphere for the same length either side of its
  // nearest point: half the chord it cuts through the sphere, Pythagoras
  // again. If it passes further from the centre than the radius, this is
  // negative and the ray misses.
  float halfChordSquared = radius * radius - nearestSquared;
  if (halfChordSquared < 0.0) return noHit;

  float entry = alongToNearest - sqrt(halfChordSquared);
  return entry > 0.0 ? entry : noHit;
}

void main() {
  // The slope of the ray through this pixel (see uFocal).
  vec2 slope = (FlutterFragCoord().xy - uSize * 0.5) / uFocal;
  // Pixel y counts down, so the direction subtracts uUp. normalize scales
  // the direction to length 1, which distanceToSphere needs.
  vec3 direction = normalize(uForward + slope.x * uRight - slope.y * uUp);

  // Each sphere the ray enters sooner than the nearest so far takes over
  // the colour, so the nearest sphere wins and hides any behind it.
  float nearest = distanceToSphere(
    direction,
    vec4(0.0, 0.0, 0.0, uCentralBodyRadius)
  );
  vec3 colour = nearest < noHit ? uCentralBodyColour : vec3(0.0);
  float entry = distanceToSphere(direction, uBody0);
  if (entry < nearest) { nearest = entry; colour = uColour0; }
  entry = distanceToSphere(direction, uBody1);
  if (entry < nearest) { nearest = entry; colour = uColour1; }
  entry = distanceToSphere(direction, uBody2);
  if (entry < nearest) { nearest = entry; colour = uColour2; }
  entry = distanceToSphere(direction, uBody3);
  if (entry < nearest) { nearest = entry; colour = uColour3; }

  if (nearest == noHit && uPlaceholders < 0.5) colour = sky(direction);
  fragColor = vec4(colour, 1.0);
}
