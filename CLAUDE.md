# homepage_v2

A portfolio presented as an interactive space map, in Flutter web.

Read `docs/architecture.md` before changing code. Its "Rules",
"Libraries and state" and "Navigation" sections are binding.

## Conventions

- A boolean variable, field or getter reads as a yes-or-no question, with
  a verb such as `is`, `has` or `can`: `isResumed`, not `resumed`. This is
  Effective Dart's "non-imperative verb phrase". A named boolean parameter
  may drop the verb, as Effective Dart suggests: `paused: false`.
- A private helper that works on one value is a member of a private
  extension on that value's type: `url.isListView`, not `_isListView(url)`.
- Use ASD-STE100 for code comments and docs.
- Comments describe the code as it is now, never how it got there.

## Commands

```sh
flutter analyze
dart format --set-exit-if-changed .
flutter test
flutter run -d web-server --web-port 8080
```
