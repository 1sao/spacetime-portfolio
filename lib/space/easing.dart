/// Slower than a smoothstep at both ends, and faster in the middle.
/// [progress] outside 0 to 1 clamps.
double easeInOutCubic(double progress) {
  final clamped = progress.clamp(0.0, 1.0);
  if (clamped < 0.5) return 4 * clamped * clamped * clamped;
  final fromEnd = 2 - 2 * clamped;
  return 1 - fromEnd * fromEnd * fromEnd / 2;
}
