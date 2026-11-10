// The pure-Dart package, so `navigation/` can import this file.
import 'package:riverpod/riverpod.dart';

import 'content/content.dart';
import 'content/site_content.dart';
import 'space/body.dart';
import 'space/scene_clock.dart';
import 'space/site_space.dart';

final contentProvider = Provider<List<Category>>((ref) => categories);

/// The body each category is drawn as, keyed by category slug. Every
/// category needs one.
final bodiesProvider = Provider<Map<String, Body>>((ref) => bodies);

/// The clock that the frame loop and the navigation share. The clock is
/// not Riverpod state, so its movement rebuilds nothing.
final sceneClockProvider = Provider<SceneClock>((ref) => SceneClock());
