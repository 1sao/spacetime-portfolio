# Architecture

## What the site is

A portfolio as one scrolling page over a live star system. A black hole sits
at the origin, and each section has a body that orbits it, except the last,
Credits, which frames the hole.

- The scene fills the window and stays fixed. The page scrolls over it.
- The page has two parts. The Landing, the first screen, shows the whole
  system. Below it, the reading screen, a panel that scrolls over the
  scene, has the text of every section. While the visitor reads a section,
  the scene frames its body.
- The system moves only when the visitor moves its clocks. Orbit time moves
  the bodies along their orbits, and spin time turns them on their axes.
  The scroll position sets the clocks and the camera, so they can go back.
  A drag on the Landing moves time, and the clocks run back when the
  visitor lets go.
- Content comes first: the page works fully while the scene loads, or if it
  never does.

This document describes the design that the code is built toward. Today the
scene shows the Landing with flat placeholder bodies, the clocks stand at 0,
and the page is plain text: scroll, drag, titles and URL fragments do not
yet move anything.

## Rendering

- **One shader draws everything:** the sky, the hole, its disc and the
  bodies, in a single ray march, so the hole lenses and eclipses the bodies.
  The bending shows only near the hole.
  Separate layers cost more than twice as much, and on the web a layer
  cannot read what is under it.
- **Overlays are Flutter widgets,** such as the body titles and their
  leaders, placed by the CPU projection. It does not bend rays: the design
  keeps the bodies that have titles out of the region where the hole's
  bending shows, and a test checks this.
- **Shader language limits** (impellerc compiles to SkSL on the web):
  - Loop bounds are constants; use `if (i >= n) break;` for a variable count.
  - No `uint` and no bit operations.
  - A uniform array is read only at a constant or loop index, and an array
    cannot be a function argument. So each body has its own uniforms.
  - Samplers are set by index on the web.
  - A `#define` name collides with any identifier of the same name.

## Layers

```
lib/
  content/     sections and their entries: data only
  space/       pure Dart: the system (orbits, bodies), the camera,
               projection, pick, the per-frame snapshot
  scene/       the frame loop, the shader wrapper with its typed uniform
               layout, the looks
  ui/          the page: the Landing, the reading screen, the colours
  debug/       debug tools, kept apart from the rest
  router.dart  the routes
  providers.dart
               providers for content/ and space/
  third_party_licences.dart
               adds the licences in LICENSES/ to Flutter's licence page
shaders/       scene.frag and its includes
LICENSES/      the licence texts of works by other authors, one file each,
               whose first line is the name of the work
bench/, tool/  the performance tour and its driver
```

`space/` and `content/` are plain Dart: they import neither Flutter nor
Riverpod. So their tests need no widgets, and a script run with `dart run`
can use them.

## Rules

1. **Compute each frame once.** One immutable snapshot per tick holds the
   camera, the two clocks and the body positions. The shader's uniforms and
   every overlay read that same snapshot, so overlays never drift from the
   scene. Its `vector_math` vectors are mutable, so nothing changes them in
   place.
2. **The shader and the CPU projection change together.**
   - `Camera.rayThrough` and `Camera.project` use the same straight rays
     as the shader. The shader's bending must not show further than
     `holeLensingRadius` from the hole.
   - A render test draws the scene with flat placeholders and checks that
     the CPU projection lands on each body's pixels.
   - Uniforms are set through one typed layout class, which binds each
     uniform by name and checks its type, so a mismatch throws when the
     shader loads.
   - The shader gets the camera's position and directions from Dart, so the
     look-at maths exists only once.
3. **Content is separate from looks.** What a section says is content. Where
   its body orbits and how it is drawn are settings, keyed by section id, so
   reordering the content does not move the bodies.
4. **Camera and time behaviour are unit-tested in pure Dart,** in `space/`,
   with no widgets.

## Libraries and state

- **Widgets:** `package:material_ui`, not the SDK's `flutter/material.dart`.
  go_router 18 is built on it.
- **State:** Riverpod 3, without code generation. Content, the router and
  settings such as the bodies are providers, so tests override them.
- **Per-frame values are not Riverpod state.** A provider owns the ticker
  and exposes a `ValueListenable<FrameSnapshot>` that painters repaint
  from. The scene reads inputs that change every frame, such as the scroll
  offset, directly at each tick.
- **The scene stands still** while the app is not resumed: on the web,
  while the window has no focus or the tab is hidden.
- **Vectors:** `vector_math_64`. Azimuth 0 points along +z, and the
  camera's right is forward × world up.

## Routing

- The site is one page at `/`. A section is a URL fragment: `/#work`.
- The URL follows the section in view without adding history entries. A
  link to `/#work` opens the page at Work.
- Any other path goes to `/`. go_router handles the routes, so pages can
  be added later.
- URLs are paths, not Flutter web's default `/#/...`; the URL strategy
  keeps the fragment.

## Web: link previews and page text

Flutter web draws text on a canvas, so search engines and link previews see
almost none of the site's words.

- **Link previews:** `web/index.html` has a `<title>`, a description and
  Open Graph tags. `App.title` repeats the `<title>`. Tests keep the tags,
  the manifest, the title and the background colour in agreement.
- **Page text:** a plain-HTML copy of the text in `index.html` waits for
  <https://github.com/flutter/rfc/pull/35>: hidden text breaks the browser's
  find-in-page. Any such text says only what the site says, for every
  visitor alike, as Google's spam policies require.

## Accessibility, motion and quality

- **Reduced motion** (`MediaQuery.disableAnimations`): no arrival, no
  drift, and cuts instead of camera moves.
- **All the site's text is on the reading screen,** as text with real
  headings, so screen readers and the keyboard reach all of it without the
  scene. Body titles are real, focusable links. The scene is decorative.
- **Quality tiers,** picked at start-up from the device and a short timing
  of the first frames: render resolution, frame rate, and lensing or a
  cheaper shader.

## Credits

The site uses these works by other authors. Each one's licence text is in
`LICENSES/`, and the site adds it to Flutter's licence page
(`lib/third_party_licences.dart`).

- **Star Nest** by Pablo Román Andrioli (Kali), with a noise clamp by
  Beibei Wang and Huw Bowles: the sky.
  <https://www.shadertoy.com/view/XlfGRj> and
  <https://www.shadertoy.com/view/XllGzN>, MIT.
