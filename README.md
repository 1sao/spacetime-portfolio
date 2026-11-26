# spacetime_portfolio

A portfolio as one scrolling page over a live star system, built with
Flutter for the web.

`docs/architecture.md` explains how the site is put together and why.

## Running it

Needs Flutter 3.50 or later.

```sh
flutter run -d chrome                  # serve the site and open Chrome
flutter build web --wasm               # build the site into build/web
flutter test                           # run the tests
dart run tool/measure_performance.dart # time start-up and frames in Chrome
```

A build with `--wasm` holds the site twice, compiled to WebAssembly and
to JavaScript, and the browser loads one of them (see
`docs/architecture.md`). `flutter run` without `--wasm` serves the
JavaScript copy, which is the one that supports hot reload. To try the
WebAssembly copy as a visitor gets it, run
`flutter run -d chrome --wasm --release --no-cross-origin-isolation`.

`tool/measure_performance.dart` builds `bench/tour.dart`, which starts the
site and holds it on the Landing, and runs it in Chrome on this machine's
GPU, by default with the frame rate unlocked. It prints the start-up times
and the frame times of each segment of the tour. `--compiler js` measures
the JavaScript build, and `--help` lists the other options. It looks for
Chrome where macOS puts it; `--chrome` gives another path.

`pubspec.yaml` lists `shaders/scene.frag` only. `flutter test` and
`flutter build` do not see a change to a file that it includes, such as
`shaders/sky.glsl`, and keep the old compiled shader. After such a change,
touch `shaders/scene.frag`. `flutter run` sees the change.
