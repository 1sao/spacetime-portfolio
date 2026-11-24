import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_address_bar/web_address_bar.dart';

import 'browser_viewport.dart'
    if (dart.library.js_interop) 'browser_viewport_web.dart';

/// The window's width, and its height with the address bar shown and
/// hidden. Layout that uses the two heights does not move when a phone's
/// address bar hides.
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

/// The first three of Material 3's window size classes. [expanded] also
/// covers the wider classes.
enum WidthClass {
  compact,
  medium,
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
