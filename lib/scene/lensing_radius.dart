import '../space/system.dart';

/// The radius of the lensing sphere that the scene is drawn with, in world
/// units: [holeLensingRadius], or the `lensing` value of the URL's query,
/// such as `?lensing=12`, to see and measure another radius.
///
/// The camera should stay outside the sphere: the shader bends nothing for
/// a camera inside it. The CPU projection and the tests use
/// [holeLensingRadius].
final double lensingRadius =
    double.tryParse(Uri.base.queryParameters['lensing'] ?? '') ??
    holeLensingRadius;
