import 'package:spacetime_portfolio/space/camera/camera.dart';

/// Desktop, short, wide, both sides of the column's breakpoint, and a
/// phone upright and on its side.
const screens = [
  Screen(width: 1600, height: 1000),
  Screen(width: 1280, height: 720),
  Screen(width: 2560, height: 900),
  Screen(width: 600, height: 800),
  Screen(width: 599, height: 800),
  Screen(width: 390, height: 844),
  Screen(width: 844, height: 390),
];

extension ScreenName on Screen {
  String get name => '${width}x$height';
}
