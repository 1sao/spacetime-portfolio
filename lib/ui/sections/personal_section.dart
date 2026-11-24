import 'package:material_ui/material_ui.dart';

import '../../content/content.dart';
import '../reading/body_text.dart';
import '../reading/device_well.dart';
import '../reading/entry.dart';
import '../reading/section_frame.dart';
import '../spacing.dart';

class PersonalSection extends StatelessWidget {
  const PersonalSection({super.key});

  @override
  Widget build(BuildContext context) => const SectionFrame(
    id: SectionId.personal,
    spacing: SiteSpacing.entryGap,
    children: [
      Entry(
        title: '[Project one]',
        details: '[Year] · [Stack]',
        children: [
          DeviceWell(caption: '[Device mock]'),
          BodyText('[Why I made it and what I learned.]'),
        ],
      ),
      Entry(
        title: '[Project two]',
        details: '[Year] · [Stack]',
        children: [
          DeviceWell(caption: '[Device mock]'),
          BodyText('[Why I made it and what I learned.]'),
        ],
      ),
    ],
  );
}
