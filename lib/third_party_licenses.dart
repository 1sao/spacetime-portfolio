import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// These works are not Dart packages, so Flutter does not find their
/// licenses, and the compiled shaders keep no license headers.
void addThirdPartyLicenses() {
  LicenseRegistry.addLicense(() async* {
    final licensePaths = (await AssetManifest.loadFromAssetBundle(rootBundle))
        .listAssets()
        .where((path) => path.startsWith('LICENSES/'));
    for (final path in licensePaths) {
      final licenseText = await rootBundle.loadString(path);
      yield LicenseEntryWithLineBreaks([licenseText.workName], licenseText);
    }
  });
}

extension on String {
  String get workName => split('\n').first;
}
