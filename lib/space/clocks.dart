/// The scene's two clocks, orbit time and spin time, from the terms that
/// add up to them.
class Clocks {
  const Clocks({this.scrollTime = 0, this.spinDrift = 0});

  final double scrollTime;

  /// Time added to the spin, but not to the orbit.
  /// Spins the body while keeping it in the same place.
  final double spinDrift;

  double get orbitTime => scrollTime;

  double get spinTime => _spinPerOrbitTime * scrollTime + spinDrift;
}

/// Bodies turn faster than they orbit, so a short scroll shows them turn.
const _spinPerOrbitTime = 2.0;

/// Time added to the spin, but not to the orbit.
/// Spins the body while keeping it in the same place.
class SpinDrift {
  double get value => _value;
  var _value = 0.0;

  void advance(double seconds) => _value += _spinDriftPerSecond * seconds;
}

const _spinDriftPerSecond = 0.1;
