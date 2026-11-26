import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// TODO: Measure the sections during layout, not after the frame, so that
// the scene gets them in the same frame and the notifier needs no clear().
final measuredReadingScreenGeometryProvider =
    NotifierProvider<ReadingScreenGeometryNotifier, ReadingScreenGeometry?>(
      ReadingScreenGeometryNotifier.new,
    );

class ReadingScreenGeometryNotifier extends Notifier<ReadingScreenGeometry?> {
  @override
  ReadingScreenGeometry? build() => null;

  set geometry(ReadingScreenGeometry geometry) => state = geometry;

  /// Waits for the widget tree to finish unmounting, when no provider may
  /// change. A new reading screen may have measured again by then.
  void clear() {
    final cleared = state;
    Future.microtask(() {
      if (ref.mounted && identical(state, cleared)) state = null;
    });
  }
}

/// Where the page's sections lie, as the reading screen measures them after
/// layout and after each change of the page's height.
@immutable
class ReadingScreenGeometry {
  ReadingScreenGeometry({
    required List<SectionSpan> sections,
    required this.maxScroll,
  }) : sections = List.unmodifiable(sections),
       assert(maxScroll >= 0);

  /// The scroll offsets at which each section's top and bottom reach the
  /// top of the view, in page order.
  final List<SectionSpan> sections;

  /// With the address bar hidden.
  final double maxScroll;

  List<double> get sectionTops => [for (final section in sections) section.top];

  /// The scroll offset at which the middle of the space above [section]
  /// reaches the top of the view. The space above the first section is as
  /// tall as the space above the second.
  double gapMiddleAbove(int section) {
    double gapAbove(int index) =>
        sections[index].top - sections[index - 1].bottom;
    final gap = switch (section) {
      0 when sections.length > 1 => gapAbove(1),
      0 => 0.0,
      _ => gapAbove(section),
    };
    return sections[section].top - gap / 2;
  }

  @override
  bool operator ==(Object other) =>
      other is ReadingScreenGeometry &&
      listEquals(other.sections, sections) &&
      other.maxScroll == maxScroll;

  @override
  int get hashCode => Object.hash(Object.hashAll(sections), maxScroll);
}

typedef SectionSpan = ({double top, double bottom});
