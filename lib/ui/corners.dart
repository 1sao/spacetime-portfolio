import 'package:material_ui/material_ui.dart';

/// The site's corner radii.
abstract final class SiteCorners {
  /// The ticks and moving pointers of a scale.
  static const tick = BorderRadius.all(Radius.circular(2));

  /// Buttons and other controls.
  static const control = BorderRadius.all(Radius.circular(6));

  /// Recessed areas that hold the device mocks.
  static const well = BorderRadius.all(Radius.circular(8));

  /// The reading screen and the time readout.
  static const screen = BorderRadius.all(Radius.circular(10));

  /// A section's card on phones.
  static const cardPhone = BorderRadius.all(Radius.circular(12));

  /// The focus outline round a body title.
  static const titleFocus = BorderRadius.all(Radius.circular(14));
}
