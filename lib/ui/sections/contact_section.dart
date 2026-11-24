import 'package:material_ui/material_ui.dart';

import '../../content/content.dart';
import '../reading/body_text.dart';
import '../reading/link_list.dart';
import '../reading/section_frame.dart';
import '../reading/text_link.dart';

class ContactSection extends StatelessWidget {
  const ContactSection({super.key});

  @override
  Widget build(BuildContext context) => const SectionFrame(
    id: SectionId.contact,
    children: [
      BodyText('[One sentence: what kind of work I am open to.]'),
      LinkList([
        (term: 'EMAIL', link: TextLink('[address]')),
        (term: 'LINKEDIN', link: TextLink('[profile]')),
        (term: 'GITHUB', link: TextLink('[profile]')),
        (term: 'CV', link: TextLink('[Download the CV, PDF]')),
      ]),
    ],
  );
}
