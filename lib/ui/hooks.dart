import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:material_ui/material_ui.dart';

/// Whether the scroll view that holds this widget is at its top. The widget
/// rebuilds only when the answer changes.
bool useIsScrolledToTop({double tolerancePx = 4}) {
  final position = Scrollable.of(useContext()).position;
  return useListenableSelector(position, () => position.pixels < tolerancePx);
}
