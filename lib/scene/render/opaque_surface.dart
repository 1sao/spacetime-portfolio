import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// The opaque surfaces over the scene, each of which an [OpaqueSurface]
/// adds while it is in the render tree.
class OpaqueSurfaceRegistry {
  final _surfaces = <_RenderOpaqueSurface>{};

  /// Each surface in [scene]'s coordinates, smaller on each side by its
  /// corner radius, so that no rounded part is in it.
  List<Rect> rectsIn(RenderObject scene) => [
    for (final surface in _surfaces)
      if (surface.hasSize) surface.rectIn(scene),
  ];
}

/// Adds its child's box to [registry] while the box is in the render tree.
class OpaqueSurface extends SingleChildRenderObjectWidget {
  const OpaqueSurface({
    super.key,
    required this.registry,
    required this.borderRadius,
    super.child,
  });

  final OpaqueSurfaceRegistry registry;
  final BorderRadius borderRadius;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderOpaqueSurface(registry, borderRadius);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) =>
      (renderObject as _RenderOpaqueSurface)
        ..registry = registry
        ..borderRadius = borderRadius;
}

class _RenderOpaqueSurface extends RenderProxyBox {
  _RenderOpaqueSurface(this._registry, this.borderRadius);

  OpaqueSurfaceRegistry _registry;
  BorderRadius borderRadius;

  set registry(OpaqueSurfaceRegistry registry) {
    if (registry == _registry) return;
    if (attached) {
      _registry._surfaces.remove(this);
      registry._surfaces.add(this);
    }
    _registry = registry;
  }

  Rect rectIn(RenderObject scene) => MatrixUtils.transformRect(
    getTransformTo(scene),
    Offset.zero & size,
  ).deflate(borderRadius.largestRadius);

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _registry._surfaces.add(this);
  }

  @override
  void detach() {
    _registry._surfaces.remove(this);
    super.detach();
  }
}

extension on BorderRadius {
  double get largestRadius => [
    topLeft,
    topRight,
    bottomLeft,
    bottomRight,
  ].expand((corner) => [corner.x, corner.y]).reduce(math.max);
}
