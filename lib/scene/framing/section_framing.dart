import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_math/vector_math_64.dart';

import '../../space/camera/camera.dart';
import '../../space/scroll/hold_lines.dart';
import '../../space/station/backdrop.dart';
import '../../space/station/framing.dart';
import '../../space/station/screen_point.dart';
import '../../viewport/reading_panel.dart';
import '../../viewport/window_size.dart';
import 'focal_lengths.dart';
import 'reading_screen_geometry.dart';
import 'scene_screen.dart';

final sectionFramingProvider = Provider<SectionFraming>(
  (ref) => SectionFraming.of(
    ref.watch(sceneScreenProvider),
    focalLength: ref.watch(focalLengthsProvider).sections,
  ),
);

/// How the sections' stations frame their bodies and the hole on a screen:
/// beside the reading panel, or between the cards.
sealed class SectionFraming {
  SectionFraming._(this._screen, this._focalLength);

  factory SectionFraming.of(Screen screen, {required double focalLength}) =>
      switch (WidthClass.of(screen.width).sectionLayout) {
        SectionLayout.panel => _BesidePanel(screen, focalLength),
        SectionLayout.cards => _BetweenCards(screen, focalLength),
      };

  final Screen _screen;
  final double _focalLength;

  HoldLines get holdLines;

  Framing bodyFraming(int section, ReadingScreenGeometry page) =>
      _framingAt(_bodyPoint(section, page));

  Framing holeFraming(int section, ReadingScreenGeometry page) =>
      _framingAt(_holePoint(section, page));

  /// The hole, as a body's station shows it behind the body.
  Backdrop get backdrop => Backdrop.hole(offsetFromBody: _peekingHoleOffset);

  Framing _framingAt(ScreenPoint point) =>
      Framing(screenPoint: point, focalLength: _focalLength);

  ScreenPoint _bodyPoint(int section, ReadingScreenGeometry page);

  /// Where a body's station shows the hole's center, from the body: right
  /// and up, in focal lengths.
  Vector2 get _peekingHoleOffset;

  ScreenPoint _holePoint(int section, ReadingScreenGeometry page);
}

/// The scene shows right of the reading panel.
class _BesidePanel extends SectionFraming {
  _BesidePanel(super._screen, super._focalLength) : super._();

  late final _panelRightFraction =
      ReadingPanel.of(_screen.width).right / _screen.width;

  late final _fixedBodyPoint = Vector2((_panelRightFraction + 1) / 2, 0.5);

  @override
  HoldLines get holdLines => HoldLines.besidePanel;

  @override
  ScreenPoint _bodyPoint(int section, ReadingScreenGeometry page) =>
      ScreenPoint.fixed(_fixedBodyPoint);

  /// On the panel's edge, so part of the hole shows beside the panel.
  @override
  Vector2 get _peekingHoleOffset =>
      Vector2(
        (_panelRightFraction - _fixedBodyPoint.x) * _screen.width,
        (_fixedBodyPoint.y - 0.62) * _screen.height,
      ) /
      _focalLength;

  /// The hole's disk is wide, so the hole sits a little farther from the
  /// panel than a body does.
  @override
  ScreenPoint _holePoint(int section, ReadingScreenGeometry page) =>
      ScreenPoint.fixed(_fixedBodyPoint + Vector2(0.04, 0));
}

/// The sections are cards across the window, and each station shows its
/// subject in the gap above its card.
class _BetweenCards extends SectionFraming {
  _BetweenCards(super._screen, super._focalLength) : super._();

  @override
  HoldLines get holdLines => HoldLines.betweenCards;

  @override
  ScreenPoint _bodyPoint(int section, ReadingScreenGeometry page) =>
      ScreenPoint.onPage(
        x: 0.5,
        scrollOffsetAtTop: page.gapMiddleAbove(section),
        screenHeight: _screen.height,
      );

  /// In focal lengths, not a fraction of the screen: a phone's short focal
  /// length would turn a fraction of its tall screen into a steep look down.
  @override
  Vector2 get _peekingHoleOffset => Vector2(0, -0.3);

  @override
  ScreenPoint _holePoint(int section, ReadingScreenGeometry page) =>
      _bodyPoint(section, page);
}
