# Architecture

## What the site is

A portfolio presented as an interactive space map. A black hole, the
central body, sits at the centre and bodies orbit it. Each body is a content
category (projects, experience, contact) and holds one beacon per message.
Messages first show in an alien glyph script and scramble into readable text
when opened.

- **Overview:** the farthest view. The camera orbits the hole slowly; drag to
  orbit, scroll to zoom.
- **Focus:** selecting a body flies the camera round the hole to it, turned to
  look past the body at the hole. The sidebar lists the body's messages,
  still in glyphs.
- **Warp:** the camera dives to the active beacon while the sky rushes past,
  and the message decodes into a card.
- **Esc / back:** returns to the overview.
- **List view:** the same content as a plain list, for anyone who doesn't
  want to fly.

## Rendering

These were settled in a prototype before this codebase started. Costs are
per frame at 2560x1600 on an Apple M3 Pro; 8.3 ms is one frame at 120 Hz.

- **One shader draws everything:** the sky, the hole, its disk and the
  bodies, in a single ray march. That costs 5.9 ms, against 14.9 ms for
  separate layers.
- **Layers can't work on web.** A layer can't read what is under it:
  `ImageFilter.shader` throws without Impeller, and a per-frame
  `toImageSync` round trip stalls.
- **Bodies are inside the ray march,** so the hole lenses and eclipses them.
  A plane cull keeps them nearly free at the overview: a ray bent toward the
  centre stays in the plane through the centre, the camera and its
  direction, so a body further than its radius from that plane can't be hit.
- **Overlays are Flutter, positioned by tracing the shader's rays on the
  CPU.** This covers labels, brackets, beacons and orbit lines. Lensing moves
  a body tens of pixels from where a straight projection puts it, so the CPU
  tracer must follow the shader's bending rule exactly.
- **Shader language limits** (impellerc compiles to SkSL on web):
  - Loop bounds must be constants; use `if (i >= n) break;` for a variable
    count.
  - No `uint` and no bit operations.
  - No arrays: four bodies are four `vec4` uniforms.
  - A `#define` name collides with any identifier of the same name.
- **Cost:**

  | Scene | Overview | Close to a body |
  |---|---|---|
  | Lensing hole with detailed bodies (prototype art) | 6.4 | 8.5 |
  | Flat placeholders | 5.7 | 5.7-7.2 |
  | Heaviest body tried, filling 30 % of the screen | | 10.5 |

  Options that aren't in use cost nothing measurable. Weaker GPUs need
  quality tiers (see "Accessibility, motion and quality").
- **Sky:** a Star Nest volume, 20 steps x 17 iterations. Sampled live, 34 %
  of bright stars blink as the view turns. Two fixes, not yet chosen
  between; the quality tier will select the variant:
  - **Direction lattice:** each pixel snaps to a fixed cell. Same cost as
    live, 5 % blink, but no nebula parallax, and the cell count must follow
    pixel density.
  - **Baked cube atlas:** 1.2 ms to draw, but a bake takes 110-210 ms on
    every warp, and lensed arcs break into dashes, because lensing
    magnifies the baked texture's individual pixels.

## Camera

- The overview sits 30 units out, beyond every focused framing: the outer
  orbit is 13.5 units, plus 6 of zoom.
- **Focusing is one eased move** in spherical coordinates (azimuth,
  elevation, distance). The camera goes round the hole, never through it.
  - It turns to face the hole 0.3 rad of yaw and 0.25 rad of pitch off
    straight behind the body, so the hole shows beside it.
  - The move takes 1.2 s for a small swing and up to 2.4 s for a half turn.
- While focused, the camera turns with the body's orbit, so the hole stays
  put. Idle auto-rotate runs only in the overview.

## Layers

```
lib/
  content/     categories and messages: data only
  space/       pure Dart, no Flutter imports: orbits, the camera rig, light
               bending, projection, the per-frame snapshot
  navigation/  overview, focus, warp and the flights between them, as a
               Riverpod Notifier over a sealed state class
  scene/       the shader wrapper, a typed uniform layout, quality tiers,
               near stars
  overlay/     labels, brackets, beacons, orbit lines
  ui/          sidebar, message card, list view, HUD
  debug/       debug panel and query flags, kept apart from the rest
  router.dart  the routes, and where a bad URL goes
  providers.dart
               providers for content/ and space/
shaders/       scene.frag and its includes
```

It is one package with these folders. If `space/` ever imports Flutter by
accident, it moves into its own package in a pub workspace, so the compiler
enforces the boundary.

## Rules

1. **Compute each frame once.** One immutable snapshot per tick holds the
   camera, the body positions and the time. The shader's uniforms and every
   overlay read that same snapshot. When each painter recomputes what it
   needs from shared mutable fields, overlays drift from the shader. The
   snapshot's vectors are `vector_math` objects, which are mutable, so
   nothing changes them in place.
2. **The shader and its CPU tracer change together.**
   - One `Bend` (light-bending) model in `space/` defines the rule; the
     shader's includes implement the same rule, and a change to one is a
     change to both.
   - A render test draws the scene with flat placeholders, finds each
     body's colour in the pixels, and checks that the CPU projection lands
     on it. Flutter can render a `FragmentProgram` inside `flutter test`.
     Perspective draws a sphere off the view axis as an ellipse centred
     further out than its projected centre, by pixels close up, so the test
     works out the ellipse's centre from the projection.
   - Uniforms are set through one typed layout class, never as
     `setFloat(34 + i, ...)`. It binds each uniform by name and checks its
     type, so a uniform renamed or retyped on one side only throws when the
     shader loads, and the render test fails.
   - The shader gets the camera's position and its forward, right and up
     directions from Dart, so the look-at maths exists only once.
3. **Content is separate from looks.** What a body says is content. Where it
   orbits and how it's drawn are settings.
   - Categories and messages have explicit slugs, so URLs don't change when
     the copy does.
   - Each category's body (its orbit, its angle along it at time 0, and its
     radius) is a setting keyed by the category's slug, so reordering the
     content doesn't move the bodies.
   - Flat placeholders act as the fake renderer. Navigation, content,
     routing and accessibility can all be built on them before the art is
     chosen.
4. **Camera behaviour is unit-tested in pure Dart,** on `space/` and
   `navigation/`, with no widgets. The tests:
   - The overview is the farthest view.
   - A focus flight is one move whose path never comes within the shadow
     radius of the central body.
   - A focus flight ends facing the central body at the configured
     angles.
   - Esc from any state ends in the overview.

## Libraries and state

- **Widgets:** `package:material_ui`, not the SDK's `flutter/material.dart`.
  go_router 18 is built on `material_ui`, whose `MaterialApp` and `Theme` are
  different classes from the SDK's, and the SDK is migrating to it.
- **State:** Riverpod 3, without code generation. The site is small enough
  for `ChangeNotifier`; Riverpod was chosen to learn it.
  - Navigation is a `Notifier` over a sealed state class. It changes only at
    transitions: it holds where a flight goes and when it started, not how
    far along it is.
  - Content, the router and settings (each category's body, body looks,
    quality tier) are providers, so tests override them.
  - `space/` and `content/` import neither Flutter nor Riverpod.
    `navigation/` imports `package:riverpod`, not `flutter_riverpod`, so its
    tests need no widgets.
  - The per-frame snapshot is not Riverpod state, so per-frame values live
    in one place and watchers hear only real transitions. A provider owns
    the ticker and exposes a `ValueListenable<FrameSnapshot>` that painters
    repaint from.
- **Vectors and matrices:** `vector_math_64`. It is pure Dart, and Flutter
  already depends on it.
- **Routing:** go_router. Each state has a URL.
  - `/` is the overview.
  - `/projects` focuses that body.
  - `/projects/project-01` is warped to its beacon, with the message open.
  - `/list` is the list view. A category's slug can't be `list`, nor
    `assets`, `canvaskit` or `packages`: `flutter run` handles paths under
    those itself instead of loading the app.
  - URLs are paths (`/projects`), not Flutter web's default `/#/projects`.
  - A bad URL goes to the nearest page above it: `/projects/nope` to
    `/projects`, `/nope` to `/`.
  - The browser's back button follows the same states as Esc.
  - Links are shareable.
  - Route changes move the camera; pages don't transition.
- **Animation:** a single `Ticker` drives the per-frame snapshot. Flights are
  plain eased interpolations in `space/`, not `AnimationController`s spread
  across widgets. The ticker runs only while the app is resumed, so the
  scene stands still while the window is unfocused or hidden, and its time
  goes on from where it stopped.

## Web: search engines and link previews

Flutter web draws text on a canvas, so search engines and link previews see
almost none of the site's words. Flutter's own guidance
(<https://docs.flutter.dev/platform-integration/web/faq>, "Search Engine
Optimization (SEO)") recommends separate HTML for content pages, or Jaspr, a
DOM-based Dart framework.

- **Link previews:** `web/index.html` has a `<title>`, a
  `<meta name="description">` and Open Graph tags. Slack, LinkedIn and
  messengers read only these and never run JavaScript. X reads the Open
  Graph title, description and image when its own tags are missing, so
  `twitter:card` is the only X tag. Flutter replaces the tab's title with
  `MaterialApp.title` once it starts, so `App.title` repeats the `<title>`.
  Tests keep the tags, the manifest, the title and the background colour
  in agreement.
- **The page's text:** postponed. The approach is a plain-HTML summary in
  `index.html`: the loading screen while Flutter starts, the whole page
  without JavaScript, and kept in the DOM afterwards for search engines and
  screen readers. Crawlers differ in what they read:
  - Google queues every page that loads (HTTP 200) for rendering in headless
    Chromium and indexes the rendered HTML
    (<https://developers.google.com/search/docs/crawling-indexing/javascript/javascript-seo-basics>),
    so text removed or hidden once Flutter starts may drop out of its index.
    Its renderer has no WebGL
    (<https://developers.google.com/search/docs/crawling-indexing/javascript/fix-search-javascript>),
    and whether Flutter's software fallback starts there is untested.
  - OpenAI's, Anthropic's and Perplexity's crawlers fetch the HTML without
    running JavaScript (<https://vercel.com/blog/the-rise-of-the-ai-crawler>,
    December 2024), so they read only what `index.html` holds.

  Hidden text breaks the browser's find-in-page:
  - Visually hidden (1 px and clipped), it is found, but there is nothing
    visible to highlight.
  - With the summary `display: none` and Flutter's semantics tree switched
    on at start-up, Chrome finds Flutter's text but neither highlights nor
    scrolls to it.

  This waits for <https://github.com/flutter/rfc/pull/35>.

Whatever text is added has to stay inside Google's spam policies
(<https://developers.google.com/search/docs/essentials/spam-policies>),
which forbid cloaking (different content for crawlers) and hidden text
placed only for search engines, while allowing screen-reader text. So
everyone gets the same HTML, with no user-agent checks, and it says only
what the site says.

A Jaspr site with the Flutter scene embedded would index better, but it is
two frameworks, and the overlays are tied to the scene. It is worth it only
if the site grows long-form pages.

## Accessibility, motion and quality

- **Reduced motion** (`MediaQuery.disableAnimations`): no sky rush on warp,
  short cuts instead of flights, no auto-rotate.
- **The list view is a first-class route,** not a debug fallback. Every
  message is reachable without the scene.
- **Semantics:** the sidebar, cards and list carry real labels. The scene is
  decorative.
- **Quality tiers,** picked at start-up from the device pixel ratio and a
  short timing of the first frames:
  - the sky variant;
  - the render-resolution cap;
  - the frame-rate cap;
  - whether bodies use full art or placeholders.
