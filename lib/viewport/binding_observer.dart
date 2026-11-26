import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

extension BindingObserver on Ref {
  /// Observes the binding until this provider is disposed.
  void observeBinding(WidgetsBindingObserver observer) {
    WidgetsBinding.instance.addObserver(observer);
    onDispose(() => WidgetsBinding.instance.removeObserver(observer));
  }
}
