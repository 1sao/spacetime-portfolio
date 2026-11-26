import 'dart:math' as math;

import '../range.dart';
import 'hold_lines.dart';

/// The scroll offsets where each station holds: first the Landing, then one
/// station for each section, of [sectionTops]. The camera moves between two
/// holds. The Landing's hold is empty: its move starts at the top of the
/// page.
List<Range> holdOffsetsFor({
  required List<double> sectionTops,
  required double viewHeight,
  required double maxScroll,
  required HoldLines lines,
}) {
  assert(sectionTops.isNotEmpty, 'The page has no sections.');
  assert(viewHeight > 0, 'The view height is $viewHeight.');
  assert(maxScroll > 0, 'The page does not scroll.');
  final minMove = _minMoveInViewHeights * viewHeight;
  final holds = [const Range(0, 0)];
  for (final top in sectionTops) {
    final start = math.max(
      top - lines.arrival * viewHeight,
      holds.last.end + minMove,
    );
    final end = math.max(start, top - lines.departure * viewHeight);
    holds.add(Range(start, end));
  }
  final fitted = _fittedToPage(holds, maxScroll);
  assert(_isInOrder(fitted), 'The holds $fitted are out of order.');
  return List.unmodifiable(fitted);
}

/// The last hold goes on to the end of the page. On a short page, the
/// stations whose holds would pass the end share the scroll left: each
/// gets an equal part, half for its move and half for its hold.
List<Range> _fittedToPage(List<Range> holds, double maxScroll) {
  final firstPastEnd = holds.indexWhere(
    (hold) => hold.end > maxScroll || hold.start >= maxScroll,
  );
  final lastFits = firstPastEnd == -1 || firstPastEnd == holds.length - 1;
  if (lastFits && holds.last.start < maxScroll) {
    return [
      ...holds.take(holds.length - 1),
      Range(holds.last.start, math.max(holds.last.end, maxScroll)),
    ];
  }
  final shareStart = holds[firstPastEnd - 1].end;
  final stationsLeft = holds.length - firstPastEnd;
  final share = (maxScroll - shareStart) / stationsLeft;
  return [
    ...holds.take(firstPastEnd),
    for (var station = 0; station < stationsLeft; station++)
      Range(
        shareStart + (station + 0.5) * share,
        shareStart + (station + 1) * share,
      ),
  ];
}

bool _isInOrder(List<Range> holds) {
  for (var station = 0; station + 1 < holds.length; station++) {
    if (holds[station + 1].start <= holds[station].end) return false;
  }
  return true;
}

/// Keeps a move from being a jump when two sections' tops are close.
const _minMoveInViewHeights = 0.05;
