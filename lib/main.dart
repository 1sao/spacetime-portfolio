import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app.dart';

void main() {
  setUrlStrategy(_CollapsingPathUrlStrategy());
  runApp(const ProviderScope(child: App()));
}

/// Path URLs with any leading slashes collapsed to one. The browser reads
/// `//projects` as the host `projects`, and the app fails to start when
/// Flutter writes that path back to the history.
class _CollapsingPathUrlStrategy extends PathUrlStrategy {
  @override
  String getPath() => super.getPath().replaceFirst(RegExp('^/+'), '/');
}
