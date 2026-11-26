# spacetime_portfolio

A portfolio as one scrolling page over a live star system, in Flutter web.

Read `docs/architecture.md` before changing code. Its "Rules",
"Structure", "Libraries and state" and "Routing" sections are binding.

## Conventions

- A boolean variable, field or getter reads as a yes-or-no question, with
  a verb such as `is`, `has` or `can`: `isResumed`, not `resumed`. This is
  Effective Dart's "non-imperative verb phrase". A named boolean parameter
  may drop the verb, as Effective Dart suggests: `paused: false`.
- One name for each concept, across types, providers, files and tests:
  `Station`, `landingStationProvider`, `station.dart`. Do not reuse a
  name that Flutter or a package in use exports: `Range`, not `Interval`.
- A choice between variants is an enum or a sealed class, named for what
  it chooses (`SectionLayout.panel`), not a boolean (`hasLandingColumn`).
- A name says if a value is a maximum or a minimum
  (`_minMoveInViewHeights`). Values that go together have names of one
  pattern: `_holdScrollTimePerViewHeight` and `_moveScrollTime`.
- A parameter that callers must think about is required. Give a default
  only to a value that nearly every caller wants.
- A private helper that works on one value is a member of a private
  extension on that value's type: `url.isListView`, not `_isListView(url)`.
- Code documents itself: names say what a value, a type or a function is,
  and the code says how. Fix an unclear name (`licenseName`, not
  `license`) before you write a comment for it.
- Comments say why, from one senior engineer to another. Use them only
  where a complex block of logic, or code that would surprise a senior
  Flutter engineer, needs it. Do not record requirements or design
  decisions in comments.
- A comment is one or two lines. Only a comment that says why the code
  does not use the obvious approach can be longer.
- Document classes rather than fields, variables or providers. A class
  with a general name (`Section`, `Credit`) gets a short doc on its
  purpose; a specific name (`StorePin`) needs none. A field gets a doc
  only if its meaning is not clear from its name (`landingFloor`).
- Keep a workaround in one file, with its reason next to it.
- Complex graphics code can have short comments on what it does.
- A doc stands alone: it does not lean on the doc above it. It defines
  its terms and units, and for a limit it says what happens past it.
- Comments describe the code as it is now. Use ASD-STE100.

## Commands

```sh
flutter analyze
dart format --set-exit-if-changed .
flutter test
flutter run -d web-server --web-port 8080
dart run tool/measure_performance.dart   # frame times in Chrome; macOS only
```
