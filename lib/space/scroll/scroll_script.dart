import 'package:vector_math/vector_math_64.dart';

import '../camera/camera.dart';
import '../clocks.dart';
import '../easing.dart';
import '../range.dart';
import '../station/station.dart';
import 'camera_route.dart';

/// What the camera does over the whole scroll: it holds at each station,
/// and moves from each station to the next.
class ScrollScript {
  /// [holdOffsets] has the scroll offsets where each of [stations] holds,
  /// and every move takes [route].
  factory ScrollScript({
    required List<Station> stations,
    required List<Range> holdOffsets,
    required CameraRoute route,
    required double viewHeight,
  }) {
    assert(holdOffsets.length == stations.length);
    final cues = <Cue>[];
    var scrollTime = 0.0;
    Range nextScrollTimes(double length) {
      final start = scrollTime;
      scrollTime += length;
      return Range(start, scrollTime);
    }

    for (final (station, offsets) in holdOffsets.indexed) {
      cues.add(
        Hold(
          stations[station],
          scrollOffsets: offsets,
          scrollTimes: nextScrollTimes(
            _holdScrollTimePerViewHeight * offsets.length / viewHeight,
          ),
        ),
      );
      if (station + 1 == stations.length) break;
      cues.add(
        Move(
          stations[station],
          stations[station + 1],
          route,
          scrollOffsets: Range(offsets.end, holdOffsets[station + 1].start),
          scrollTimes: nextScrollTimes(_moveScrollTime),
        ),
      );
    }
    return ScrollScript._(List.unmodifiable(cues));
  }

  /// Holds at [station] at every scroll offset, with the scroll time at 0.
  ScrollScript.holding(Station station)
    : cues = List.unmodifiable([
        Hold(
          station,
          scrollOffsets: const Range(0, 0),
          scrollTimes: const Range(0, 0),
        ),
      ]);

  ScrollScript._(this.cues);

  /// A hold for each station, with a move between each two.
  final List<Cue> cues;

  /// A scroll past either end of the page, as a bounce does, gives the
  /// cue at that end.
  Cue cueAt(double scrollOffset) => cues.firstWhere(
    // A move ends where the next hold starts.
    (cue) => switch (cue) {
      Hold() => scrollOffset <= cue.scrollOffsets.end,
      Move() => scrollOffset < cue.scrollOffsets.end,
    },
    orElse: () => cues.last,
  );

  double scrollTimeAt(double scrollOffset) =>
      cueAt(scrollOffset).scrollTimeAt(scrollOffset);

  Camera cameraAt(double scrollOffset, double orbitTime) =>
      cueAt(scrollOffset).cameraAt(scrollOffset, orbitTime);
}

/// A part of a [ScrollScript]: a [Hold] or a [Move].
sealed class Cue {
  const Cue({required this.scrollOffsets, required this.scrollTimes});

  final Range scrollOffsets;

  /// The scroll time at the start and the end of [scrollOffsets].
  final Range scrollTimes;

  double scrollTimeAt(double scrollOffset);

  Camera cameraAt(double scrollOffset, double orbitTime);
}

/// While the camera holds at [station], the time runs on slowly with the
/// scroll.
final class Hold extends Cue {
  const Hold(
    this.station, {
    required super.scrollOffsets,
    required super.scrollTimes,
  });

  final Station station;

  @override
  double scrollTimeAt(double scrollOffset) =>
      scrollTimes.at(scrollOffsets.fractionAt(scrollOffset));

  @override
  Camera cameraAt(double scrollOffset, double orbitTime) =>
      station.cameraAt(orbitTime, scrollOffset: scrollOffset);
}

/// The camera moves from [from] to [to] along [route], and the time eases
/// on by a fixed amount.
final class Move extends Cue {
  const Move(
    this.from,
    this.to,
    this.route, {
    required super.scrollOffsets,
    required super.scrollTimes,
  });

  final Station from;
  final Station to;
  final CameraRoute route;

  @override
  double scrollTimeAt(double scrollOffset) =>
      scrollTimes.at(easeInOutCubic(scrollOffsets.fractionAt(scrollOffset)));

  /// Both stations' cameras follow their bodies to [orbitTime], so the move
  /// ends on the next body where it is now.
  @override
  Camera cameraAt(double scrollOffset, double orbitTime) {
    Camera cameraOf(Station station, double orbitTime) =>
        station.cameraAt(orbitTime, scrollOffset: scrollOffset);
    final departureOrbitTime = Clocks(scrollTime: scrollTimes.start).orbitTime;
    return mixCameras(
      cameraOf(from, orbitTime),
      cameraOf(to, orbitTime),
      smoothStep(0, 1, scrollOffsets.fractionAt(scrollOffset)),
      route,
      fromAtDeparture: cameraOf(from, departureOrbitTime),
      toAtDeparture: cameraOf(to, departureOrbitTime),
    );
  }
}

/// While a station holds, the scroll time follows the scroll: it runs on
/// by this much for each view height that the page scrolls.
const _holdScrollTimePerViewHeight = 0.27;

/// Each move adds this much to the scroll time, however long its scroll
/// is. The time eases in and out, so the bodies move fastest in the
/// middle of the move.
const _moveScrollTime = 3.0;
