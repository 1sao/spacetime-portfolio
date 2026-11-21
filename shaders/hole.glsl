// The hole's march, from "Black Hole" by nethe550
// (https://www.shadertoy.com/view/tXsGR2), MIT licence. Shared by
// scene.frag and hole_textures.frag.
//
// The hole works in its own units, "hole units": the disc's outer edge is
// torusOuter of them. Its pull bends a ray only inside the lensing sphere,
// and fades to nothing at the sphere's edge.

// The disc's density is a torus round the hole, discFlattening times
// thinner than it is wide. So the disc's half-thickness is
// discHalfThickness.
const float torusCentre = 0.8;
const float torusMinor = 0.99;
const float torusOuter = torusCentre + torusMinor;
const float discFlattening = 25.0;
const float discHalfThickness = torusMinor / discFlattening;

// World units for each hole unit, for a disc whose outer edge is
// discOuter world units.
float holeUnit(float discOuter) {
  return discOuter / torusOuter;
}
// The march catches a ray that comes this near the hole.
const float holeHorizon = 0.1;
// The march's step, at the ray's starting speed.
const float holeStep = 0.02;
const float holePi = 3.14159265358979;

// The path table, which hole_textures.frag bakes: for each impact
// parameter b (how far from the hole the straight ray would pass), the
// path of the ray that enters the lensing sphere at b, in the plane of the
// ray and the hole. In that plane, the hole is at 0, the ray enters at
// (-sqrt(sphere^2 - b^2), b) heading along +x, and the pull turns it
// toward -y.
//
// Columns are b from 0 to the sphere's radius. Rows 0 to pathPoints - 1
// hold the x of each point of the path, the next pathPoints rows its y,
// then a row for how far the ray has turned when it leaves the sphere, and
// a row for the glow it gathers. Each value is in two channels (see
// split16 in hole_textures.frag).
//
// The march stores a point each time the ray has turned pathCutSweep round
// the hole, or gone pathCutLength, since the last point, whichever comes
// first. It stops where the ray leaves the sphere or the hole catches it,
// and the points after that are all that last point.
const int pathPoints = 16;
const float pathColumns = 512.0;
const float pathRows = 2.0 * float(pathPoints) + 2.0;
const float pathCutSweep = holePi / 6.0;
const float pathCutLength = 0.5;
const float turnRow = 2.0 * float(pathPoints);
const float glowRow = turnRow + 1.0;
const float turnLimit = 3.0 * holePi;
const float glowLimit = 2.0;

// How much of the pull acts at r from the hole: all of it near the hole,
// none at the lensing sphere's edge.
float pullShare(float r, float sphere) {
  return smoothstep(sphere, 0.5 * sphere, r);
}
