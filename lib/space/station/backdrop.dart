import 'package:vector_math/vector_math_64.dart';

/// What a body's station keeps in view behind its body, and where.
sealed class Backdrop {
  factory Backdrop.hole({required Vector2 offsetFromBody}) = _HoleBackdrop;

  /// Right and up, in focal lengths.
  Vector2 get offsetFromBody;

  Vector3 positionAt(double orbitTime);
}

class _HoleBackdrop implements Backdrop {
  _HoleBackdrop({required this.offsetFromBody});

  @override
  final Vector2 offsetFromBody;

  @override
  Vector3 positionAt(double orbitTime) => Vector3.zero();
}
