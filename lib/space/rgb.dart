/// A color as red, green and blue. A component can be more than 1: the
/// shaders add and multiply light, and some looks use bright values.
class Rgb {
  const Rgb(this.red, this.green, this.blue);

  const Rgb.gray(double value) : this(value, value, value);

  final double red;
  final double green;
  final double blue;
}
