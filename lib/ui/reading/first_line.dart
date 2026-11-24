import 'package:material_ui/material_ui.dart';

import '../previews.dart';
import '../spacing.dart';
import '../type.dart';

class FirstLine extends StatelessWidget {
  const FirstLine(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final style = context.type.firstLine;
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: SiteSpacing.firstLineMaxWidth,
      ),
      child: Text(text, style: style),
    );
  }
}

@ReadingPreview('FirstLine')
Widget firstLinePreview() =>
    const FirstLine('[One line: who I am and what I build.]');
