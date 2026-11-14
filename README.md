# homepage_v2

A portfolio presented as an interactive space map, built with Flutter for the web.

`docs/architecture.md` explains how the site is put together and why.

## Running it

Needs Flutter 3.47 or later.

```sh
flutter run -d chrome                  # serve the site locally and open it in Chrome
flutter test                           # run the tests
dart run tool/measure_performance.dart # time the frames of a tour of the site in Chrome
```

`tool/measure_performance.dart` builds `bench/tour.dart`, a tour of the
site by URL changes, and runs it in Chrome on this machine's GPU with the
frame rate unlocked. It prints the frame times of each flight and each
stop. It looks for Chrome where macOS puts it; `--chrome` gives another
path.

`pubspec.yaml` lists `shaders/scene.frag` only. `flutter test` and
`flutter build` do not see a change to a file that it includes, such as
`shaders/sky.glsl`, and keep the old compiled shader. After such a change,
touch `shaders/scene.frag`. `flutter run` sees the change.
