/// The time of the scene. Orbits, flights and the frame snapshot use this
/// one time, so that they agree.
///
/// The frame loop moves the clock forward. The clock stands still when no
/// frame loop moves it.
class SceneClock {
  /// The time of the scene, in seconds.
  double get now => _now;
  double _now = 0;

  /// Moves the clock forward to [time], in seconds. The clock does not go
  /// back.
  void advanceTo(double time) {
    assert(time >= _now, 'The clock does not go back.');
    _now = time;
  }
}
