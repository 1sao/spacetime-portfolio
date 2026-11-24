import 'package:material_ui/material_ui.dart';

import '../previews.dart';
import '../type.dart';

class BodyText extends StatelessWidget {
  const BodyText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(text, style: context.type.body);
}

@ReadingPreview('BodyText')
Widget bodyTextPreview() => const BodyText(
  '[Two or three sentences about my work: the platforms, the kind of '
  'teams, what I care about in an app.]',
);
