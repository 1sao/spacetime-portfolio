import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_address_bar/web_address_bar.dart';

import 'browser_viewport.dart'
    if (dart.library.js_interop) 'browser_viewport_web.dart';

/// The window's height with the browser's address bar shown and with it
/// hidden, in logical pixels.
///
/// While [WebAddressBar] is active, a phone's browser hides its address bar
/// as the page scrolls down and shows it as the page scrolls up, and the
/// window's height changes with it. These two heights do not change when
/// the bar moves, only when the window turns or is resized. Layout that
/// must not move under the visitor's finger should use them instead of the
/// window's height.
@immutable
class ViewportHeights {
  const ViewportHeights({required this.small, required this.large})
    : assert(small <= large);

  /// The height while the address bar shows, as CSS `100svh`.
  final double small;

  /// The height while the address bar is hidden, as CSS `100lvh`.
  final double large;

  @override
  bool operator ==(Object other) =>
      other is ViewportHeights && other.small == small && other.large == large;

  @override
  int get hashCode => Object.hash(small, large);
}

final viewportHeightsProvider =
    NotifierProvider<ViewportHeightsNotifier, ViewportHeights>(
      ViewportHeightsNotifier.new,
    );

/// Measures [ViewportHeights] again each time the window's size changes.
class ViewportHeightsNotifier extends Notifier<ViewportHeights>
    with WidgetsBindingObserver {
  @override
  ViewportHeights build() {
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() => WidgetsBinding.instance.removeObserver(this));
    return _measure();
  }

  @override
  void didChangeMetrics() => state = _measure();

  ViewportHeights _measure() {
    if (WebAddressBar.isActive) {
      final (:small, :large) = measureBrowserViewport();
      // A browser without `svh` and `lvh` measures 0 for both.
      if (small > 0 && large > 0) {
        return ViewportHeights(small: small, large: large);
      }
    }
    // Without WebAddressBar the address bar does not hide, so both heights
    // are the window's height.
    final view = WidgetsBinding.instance.platformDispatcher.implicitView!;
    final height = view.physicalSize.height / view.devicePixelRatio;
    return ViewportHeights(small: height, large: height);
  }
}
