import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'binding_observer.dart';

final isMotionReducedProvider = NotifierProvider<MotionReducedNotifier, bool>(
  MotionReducedNotifier.new,
);

/// The system's reduced-motion setting, as `MediaQuery.disableAnimations`
/// gives it to widgets, for code without a context.
class MotionReducedNotifier extends Notifier<bool> with WidgetsBindingObserver {
  @override
  bool build() {
    ref.observeBinding(this);
    return _isReducedNow;
  }

  @override
  void didChangeAccessibilityFeatures() => state = _isReducedNow;

  bool get _isReducedNow => WidgetsBinding
      .instance
      .platformDispatcher
      .accessibilityFeatures
      .disableAnimations;
}
