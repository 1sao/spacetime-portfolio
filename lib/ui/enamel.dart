import 'package:material_ui/material_ui.dart';

import 'colors.dart';
import 'corners.dart';

class EnamelDecoration extends Decoration {
  const EnamelDecoration({
    required this.color,
    required this.borderRadius,
    required this.innerShadow,
  });

  const EnamelDecoration.panel({required BorderRadius borderRadius})
    : this(
        color: SiteColors.enamel,
        borderRadius: borderRadius,
        innerShadow: _highlight,
      );

  const EnamelDecoration.well()
    : this(
        color: SiteColors.enamelWell,
        borderRadius: SiteCorners.well,
        innerShadow: _wellShadow,
      );

  // The rim covers the top pixel, so the highlight shows in the second.
  static const _highlight = BoxShadow(
    color: Color(0x0FFFF0D2),
    offset: Offset(0, 2),
  );

  static const _wellShadow = BoxShadow(
    color: Color(0x80000000),
    offset: Offset(0, 3),
    blurRadius: 8,
  );

  final Color color;
  final BorderRadius borderRadius;
  final BoxShadow innerShadow;

  @override
  bool hitTest(Size size, Offset position, {TextDirection? textDirection}) =>
      borderRadius.toRRect(Offset.zero & size).contains(position);

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _EnamelPainter(this);
}

class _EnamelPainter extends BoxPainter {
  _EnamelPainter(this.decoration);

  final EnamelDecoration decoration;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final surface = decoration.borderRadius.toRRect(
      offset & configuration.size!,
    );
    final shadow = decoration.innerShadow;
    canvas
      ..drawRRect(surface, Paint()..color = decoration.color)
      // Flutter has no inner shadow: this draws the area outside a moved
      // copy of the surface, clipped to the surface.
      ..save()
      ..clipRRect(surface)
      ..drawPath(
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRect(
            surface.outerRect.inflate(
              shadow.offset.distance + 3 * shadow.blurSigma,
            ),
          )
          ..addRRect(surface.shift(shadow.offset)),
        shadow.toPaint(),
      )
      ..restore()
      ..drawRRect(
        surface.deflate(0.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = SiteColors.enamelRim,
      );
  }
}
