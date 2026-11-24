import 'package:material_ui/material_ui.dart';

import '../previews.dart';
import '../spacing.dart';
import '../type.dart';
import 'body_text.dart';
import 'device_well.dart';
import 'heading.dart';

class Entry extends StatelessWidget {
  const Entry({
    super.key,
    required this.title,
    required this.details,
    required this.children,
  });

  final String title;
  final String details;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final type = context.type;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: SiteSpacing.paragraph,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 6,
          children: [
            Heading(title, level: 3, style: type.entryHeading),
            Text(details, style: type.entryDetails),
          ],
        ),
        ...children,
      ],
    );
  }
}

@ReadingPreview('Entry')
Widget entryPreview() => const Entry(
  title: '[Project]',
  details: '[Client] · [Years] · [Platforms]',
  children: [
    DeviceWell(caption: '[Device mock]'),
    BodyText('[What the app does, and my part in it.]'),
  ],
);
