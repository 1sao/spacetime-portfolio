import 'dart:io';

import 'package:flutter/services.dart';
import 'package:spacetime_portfolio/ui/type.dart';

Future<void> loadSiteFonts() async {
  for (final (family, file) in [
    (SiteFonts.saira, 'fonts/Saira.ttf'),
    (SiteFonts.atkinson, 'fonts/AtkinsonHyperlegibleNext.ttf'),
  ]) {
    final bytes = File(file).readAsBytesSync();
    await (FontLoader(
      family,
    )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
  }
}
