import 'package:flutter_test/flutter_test.dart';

/// Matches a number equal to [value] apart from the rounding errors of
/// floating-point arithmetic.
Matcher nearlyEquals(num value) => closeTo(value, 1e-9);

/// Matches a number at least [value], apart from rounding errors.
Matcher atLeastNearly(num value) => greaterThanOrEqualTo(value - 1e-9);

/// Matches a number at most [value], apart from rounding errors.
Matcher atMostNearly(num value) => lessThanOrEqualTo(value + 1e-9);
