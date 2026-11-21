import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:web_address_bar/web_address_bar.dart';

import 'app.dart';
import 'third_party_licences.dart';

void main() {
  setUrlStrategy(_CollapsingPathUrlStrategy());
  addThirdPartyLicences();
  // Lets a phone's browser hide its address bar as the page scrolls.
  WebAddressBar.enable();
  runApp(const ProviderScope(child: App()));
}

/// Path URLs with any leading slashes collapsed to one, and with the
/// fragment, which names a section (`/#work`). The browser reads `//work`
/// as the host `work`, and the app fails to start when Flutter writes that
/// path back to the history.
class _CollapsingPathUrlStrategy extends PathUrlStrategy {
  _CollapsingPathUrlStrategy()
    : super(BrowserPlatformLocation(), /* includeHash: */ true);

  @override
  String getPath() => super.getPath().replaceFirst(RegExp('^/+'), '/');
}
