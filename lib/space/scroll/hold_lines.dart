import 'hold_offsets.dart';

/// Where [holdOffsetsFor] puts each section's hold: a section's station
/// holds while the section's top is between two lines across the view. A
/// section's top is the top edge of its panel or card. A line is a
/// fraction of the view's height, measured down from the view's top: at
/// 0.25, the line is 25% of the way down, and below 0 it is above the view.
enum HoldLines {
  /// The sections are in a reading panel, and the scene shows right of it.
  besidePanel(arrival: 0.25, departure: -0.15),

  /// The sections are cards across the view, and the body shows above its
  /// card, so a station arrives while the card is still low in the view.
  betweenCards(arrival: 0.62, departure: 0);

  const HoldLines({required this.arrival, required this.departure});

  /// The station's hold starts when its section's top comes up to this
  /// line.
  final double arrival;

  /// The station's hold ends, and the move to the next station starts,
  /// when its section's top comes up to this line.
  final double departure;
}
