import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Adds each licence file in `LICENSES/` to the [LicenseRegistry], which
/// Flutter's licence page shows.
///
/// These works are not Dart packages, so Flutter does not find their
/// licences by itself. The compiled shaders have no comments, so the
/// licence headers in the shader sources are not in the built site.
void addThirdPartyLicences() {
  LicenseRegistry.addLicense(() async* {
    final licenses = (await AssetManifest.loadFromAssetBundle(rootBundle))
        .listAssets()
        .where((path) => path.startsWith('LICENSES/'));
    for (final licenseKey in licenses) {
      final licenseText = await rootBundle.loadString(licenseKey);
      yield LicenseEntryWithLineBreaks([licenseText.title], licenseText);
    }
  });
}

extension on String {
  /// The first line of a licence file is the name of the work.
  String get title => split('\n').first;
}
