import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final isSceneRunningProvider = NotifierProvider<SceneRunning, bool>(
  SceneRunning.new,
);

/// The scene stands still while the app is not resumed: on the web, while
/// the window has no focus or the tab is hidden.
class SceneRunning extends Notifier<bool> {
  @override
  bool build() {
    final lifecycle = AppLifecycleListener(
      onStateChange: (lifecycleState) => state = lifecycleState.isResumed,
    );
    ref.onDispose(lifecycle.dispose);
    return SchedulerBinding.instance.lifecycleState.isResumed;
  }
}

extension on AppLifecycleState? {
  // On the web, the state is null until the first change: the page starts
  // resumed, and the engine reports only changes. Tests also start with null.
  bool get isResumed => this == null || this == AppLifecycleState.resumed;
}
