import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../providers.dart';
import 'colours.dart';
import 'corners.dart';
import 'spacing.dart';
import 'type.dart';

/// Every section and entry as text, on one panel.
class ReadingScreen extends ConsumerWidget {
  const ReadingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(contentProvider);
    final type = ref.watch(siteTypeProvider);

    return Align(
      alignment: Alignment.topLeft,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 860),
        margin: const EdgeInsets.symmetric(horizontal: SiteSpacing.gutter),
        padding: const EdgeInsets.fromLTRB(
          SiteSpacing.readerPad,
          30,
          SiteSpacing.readerPad,
          80,
        ),
        decoration: const BoxDecoration(
          color: SiteColours.enamel,
          borderRadius: SiteCorners.screen,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: SiteSpacing.sectionGap,
          children: [
            for (final section in content)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: SiteSpacing.headingGap,
                children: [
                  _Heading(section.title, level: 2, style: type.sectionHeading),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: SiteSpacing.entryGap,
                    children: [
                      for (final entry in section.entries)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: SiteSpacing.xs,
                          children: [
                            _Heading(
                              entry.title,
                              level: 3,
                              style: type.entryHeading,
                            ),
                            Text(entry.text, style: type.body),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text, {required this.level, this.style});

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
