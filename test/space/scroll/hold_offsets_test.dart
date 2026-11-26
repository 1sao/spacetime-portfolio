import 'package:flutter_test/flutter_test.dart';
import 'package:spacetime_portfolio/space/scroll/hold_lines.dart';
import 'package:spacetime_portfolio/space/scroll/hold_offsets.dart';

void main() {
  const viewHeight = 800.0;

  /// Every section is taller than the view.
  const tallSections = [700.0, 2600.0, 3800.0, 6000.0, 7400.0];
  const tallSectionsMaxScroll = 8600.0;

  final layouts = {
    'tall sections': (tops: tallSections, maxScroll: tallSectionsMaxScroll),
    'short first section': (
      tops: [700.0, 820.0, 2600.0, 3800.0, 5000.0],
      maxScroll: 5600.0,
    ),
    'boundaries a few pixels apart': (
      tops: [700.0, 1500.0, 1510.0, 1520.0, 2400.0],
      maxScroll: 2800.0,
    ),
    'a view taller than most sections': (
      tops: [1800.0, 2300.0, 2900.0, 3400.0, 3900.0],
      maxScroll: 1700.0,
    ),
  };

  for (final (layoutName, lines) in [
    ('panel', HoldLines.besidePanel),
    ('cards', HoldLines.betweenCards),
  ]) {
    for (final MapEntry(key: name, value: layout) in layouts.entries) {
      test(
        '$layoutName, $name: the holds come in page order, with a move of at '
        'least 10 px between each two',
        () {
          final holds = holdOffsetsFor(
            sectionTops: layout.tops,
            viewHeight: viewHeight,
            maxScroll: layout.maxScroll,
            lines: lines,
          );
          expect(holds, hasLength(layout.tops.length + 1));
          expect(holds.first.start, 0);
          for (var station = 0; station + 1 < holds.length; station++) {
            expect(
              holds[station + 1].start - holds[station].end,
              greaterThanOrEqualTo(10),
              reason: 'after station $station',
            );
          }
        },
      );
    }

    final holds = holdOffsetsFor(
      sectionTops: tallSections,
      viewHeight: viewHeight,
      maxScroll: tallSectionsMaxScroll,
      lines: lines,
    );

    test("$layoutName: each section's station holds when the section's top "
        'reaches the top of the view, and a little above it', () {
      for (var section = 0; section < tallSections.length; section++) {
        final hold = holds[section + 1];
        for (final offset in [
          tallSections[section] - 40,
          tallSections[section],
        ]) {
          expect(
            offset,
            inInclusiveRange(hold.start, hold.end),
            reason: 'section $section at $offset',
          );
        }
      }
    });
  }
}
