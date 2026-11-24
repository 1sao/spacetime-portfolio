import 'package:material_ui/material_ui.dart';

import '../../content/content.dart';
import '../reading/body_text.dart';
import '../reading/first_line.dart';
import '../reading/section_frame.dart';

class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) => const SectionFrame(
    id: SectionId.about,
    children: [
      FirstLine('[One line: who I am and what I build.]'),
      BodyText(
        '[Two or three sentences about my work: the platforms, the kind of '
        'teams, what I care about in an app.]',
      ),
      BodyText('[Where I work now, and what I look for next.]'),
    ],
  );
}
