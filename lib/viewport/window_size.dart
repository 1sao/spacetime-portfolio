import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_address_bar/web_address_bar.dart';

import 'browser_viewport.dart'
    if (dart.library.js_interop) 'browser_viewport_web.dart';

/// The window's width, and its height with the browser's address bar
/// shown and with it hidden, in logical pixels.
///
/// While [WebAddressBar] is active, a phone's browser hides its address bar
/// as the page scrolls down and shows it as the page scrolls up, and the
/// window's height changes with it. The two heights do not change when the
/// bar moves, only when the window turns or is resized. Layout that must
/// not move under the visitor's finger should use them instead of the
/// window's height.
@immutable
class WindowSize {
  const WindowSize({
    required this.width,
    required this.smallHeight,
    required this.largeHeight,
  }) : assert(smallHeight <= largeHeight);

  final double width;

  /// The height while the address bar shows, as CSS `100svh`.
  final double smallHeight;

  /// The height while the address bar is hidden, as CSS `100lvh`.
  final double largeHeight;

  /// The [WidthClass] of [width].
  WidthClass get widthClass => WidthClass.of(width);

  @override
  bool operator ==(Object other) =>
      other is WindowSize &&
      other.width == width &&
      other.smallHeight == smallHeight &&
      other.largeHeight == largeHeight;

  @override
  int get hashCode => Object.hash(width, smallHeight, largeHeight);
}

/// The first three of Material 3's window size classes, by width.
enum WidthClass {
  /// Under 600 logical pixels: phones held upright.
  compact,

  /// 600 to 839.
  medium,

  /// 840 or more, which also covers Material 3's wider classes.
  expanded;

  static WidthClass of(double width) => switch (width) {
    < 600 => compact,
    < 840 => medium,
    _ => expanded,
  };
}

final windowSizeProvider = NotifierProvider<WindowSizeNotifier, WindowSize>(
  WindowSizeNotifier.new,
);

/// Measures [WindowSize] again each time the window's size changes.
class WindowSizeNotifier extends Notifier<WindowSize>
    with WidgetsBindingObserver {
  @override
  WindowSize build() {
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() => WidgetsBinding.instance.removeObserver(this));
    return _measure();
  }

  @override
  void didChangeMetrics() => state = _measure();

  WindowSize _measure() {
    final view = WidgetsBinding.instance.platformDispatcher.implicitView!;
    final size = view.physicalSize / view.devicePixelRatio;
    // Without WebAddressBar the address bar does not hide.
    var (small, large) = (size.height, size.height);
    if (WebAddressBar.isActive) {
      final measured = measureBrowserViewportHeights();
      // A browser without `svh` and `lvh` measures 0 for both.
      if (measured.small > 0 && measured.large > 0) {
        (small, large) = (measured.small, measured.large);
      }
    }
    return WindowSize(
      width: size.width,
      smallHeight: small,
      largeHeight: large,
    );
  }
}
