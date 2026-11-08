# homepage_v2

A portfolio presented as an interactive space map, in Flutter web.

Read `docs/architecture.md` before changing code. Its "Rules" and
"Libraries and state" sections are binding.

## Conventions

- A boolean variable, field or getter reads as a yes-or-no question, with
  a verb such as `is`, `has` or `can`: `isResumed`, not `resumed`. This is
  Effective Dart's "non-imperative verb phrase". A named boolean parameter
  may drop the verb, as Effective Dart suggests: `paused: false`.

## Commands

```sh
flutter analyze
dart format --set-exit-if-changed .
flutter test
flutter run -d web-server --web-port 8080
```
