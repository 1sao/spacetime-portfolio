import 'package:flutter_test/flutter_test.dart';

import 'pump_app.dart';

void main() {
  testWidgets('a section fragment stays in the URL', (tester) async {
    await pumpApp(tester, firstUrl: '/#work');
    expect(tester.currentUrl.toString(), '/#work');
  });

  testWidgets('any other path goes to the page, and keeps its fragment', (
    tester,
  ) async {
    await pumpApp(tester, firstUrl: '/nope/deeper?a=1#work');
    expect(tester.currentUrl.toString(), '/#work');
  });
}
