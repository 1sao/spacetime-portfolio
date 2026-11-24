import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../content/content.dart';
import '../../providers.dart';
import '../previews.dart';
import '../spacing.dart';
import '../type.dart';
import 'body_text.dart';
import 'first_line.dart';
import 'heading.dart';

class SectionFrame extends ConsumerWidget {
  const SectionFrame({
    super.key,
    required this.id,
    this.spacing = SiteSpacing.paragraph,
    required this.children,
  });

  final SectionId id;
  final double spacing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final section = ref
        .watch(contentProvider)
        .firstWhere((section) => section.id == id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Heading(section.title, level: 2, style: context.type.sectionHeading),
        const SizedBox(height: SiteSpacing.headingGap),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: spacing,
          children: children,
        ),
      ],
    );
  }
}

@ReadingPreview('SectionFrame')
Widget sectionFramePreview() => const SectionFrame(
  id: SectionId.about,
  children: [
    FirstLine('[One line: who I am and what I build.]'),
    BodyText('[Where I work now, and what I look for next.]'),
  ],
);
