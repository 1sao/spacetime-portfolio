import 'package:material_ui/material_ui.dart';

class Heading extends StatelessWidget {
  const Heading(this.text, {super.key, required this.level, this.style});

  final String text;
  final int level;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      headingLevel: level,
      child: Text(text, style: style),
    );
  }
}
