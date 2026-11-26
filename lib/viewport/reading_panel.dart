import '../ui/spacing.dart';
import 'window_size.dart';

/// Where the reading panel lies across a window of [WidthClass.expanded].
class ReadingPanel {
  ReadingPanel.of(double windowWidth)
    : left = SiteSpacing.gutter + (0.02 * windowWidth).clamp(0.0, 32.0),
      width = (0.56 * windowWidth).clamp(470.0, 860.0);

  final double left;
  final double width;

  double get right => left + width;
}
