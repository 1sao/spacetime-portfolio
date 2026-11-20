import 'package:flutter_test/flutter_test.dart';

/// Matches a number equal to [value] apart from the rounding errors of
/// floating-point arithmetic.
Matcher nearlyEquals(num value) => closeTo(value, 1e-9);
