import 'package:flutter_test/flutter_test.dart';
import 'package:homepage_v2/navigation/map_location.dart';

import '../fake_content.dart';

void main() {
  test('each location reaches the overview in two parents or fewer', () {
    for (final location in fakeLocations) {
      var current = location;
      for (var steps = 0; steps < 2 && current.parent != null; steps++) {
        current = current.parent!;
      }
      expect(current, const OverviewLocation(), reason: location.path);
    }
  });
}
