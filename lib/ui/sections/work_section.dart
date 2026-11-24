import 'package:material_ui/material_ui.dart';

import '../../content/content.dart';
import '../reading/body_text.dart';
import '../reading/device_well.dart';
import '../reading/entry.dart';
import '../reading/section_frame.dart';
import '../spacing.dart';

class WorkSection extends StatelessWidget {
  const WorkSection({super.key});

  @override
  Widget build(BuildContext context) => const SectionFrame(
    id: SectionId.work,
    spacing: SiteSpacing.entryGap,
    children: [
      Entry(
        title: 'White-label loyalty apps',
        details: '[Client] · [Years] · [Platforms]',
        children: [
          DeviceWell(caption: '[Device mock]'),
          BodyText(
            '[What the client needed, what the team built, and my part '
            'in it.]',
          ),
          BodyText('[One result that a number or a store rating shows.]'),
        ],
      ),
      Entry(
        title: 'Truck tablets',
        details: '[Client] · [Years] · [Platforms]',
        children: [
          DeviceWell(caption: '[Device mock]'),
          BodyText('[The problem in the cab, and how the app solved it.]'),
          BodyText('[My part: the parts of the app I designed or built.]'),
        ],
      ),
      Entry(
        title: 'Speech trainer',
        details: '[Client] · [Years] · [Platforms]',
        children: [
          DeviceWell(caption: '[Device mock]'),
          BodyText('[Who uses it and what it trains.]'),
          BodyText('[The hardest technical part, in one or two sentences.]'),
        ],
      ),
      Entry(
        title: 'Parental control',
        details: '[Years] · [Platforms]',
        children: [
          DeviceWell(caption: '[Device mock]'),
          BodyText('[What the app does for parents, and my part in it.]'),
          BodyText('[One result that a number or a store rating shows.]'),
        ],
      ),
    ],
  );
}
