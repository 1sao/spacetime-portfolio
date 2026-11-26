import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../viewport/window_size.dart';
import '../colors.dart';
import '../previews.dart';
import '../spacing.dart';
import '../type.dart';
import 'text_link.dart';

typedef LinkListItem = ({String term, TextLink link});

class LinkList extends ConsumerWidget {
  const LinkList(this.items, {super.key});

  final List<LinkListItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = context.type.listLabel;
    final layout = ref.watch(
      windowSizeProvider.select((window) => window.widthClass.sectionLayout),
    );
    return layout == SectionLayout.panel
        ? _LinkTable(items, termStyle: style)
        : _StackedLinks(items, termStyle: style);
  }
}

const _divider = BoxDecoration(
  border: Border(
    bottom: BorderSide(
      color: SiteColors.enamelRim,
      width: SiteSpacing.hairline,
    ),
  ),
);

class _LinkTable extends StatelessWidget {
  const _LinkTable(this.items, {required this.termStyle});

  final List<LinkListItem> items;
  final TextStyle termStyle;

  static const _termColumnMinWidth = 157.0;

  @override
  Widget build(BuildContext context) => Table(
    columnWidths: const {
      0: MaxColumnWidth(
        IntrinsicColumnWidth(),
        FixedColumnWidth(_termColumnMinWidth),
      ),
    },
    children: [
      for (final (:term, :link) in items)
        TableRow(
          decoration: _divider,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 22, 24, 22),
              child: Text(term, style: termStyle),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 19),
              child: link,
            ),
          ],
        ),
    ],
  );
}

class _StackedLinks extends StatelessWidget {
  const _StackedLinks(this.items, {required this.termStyle});

  final List<LinkListItem> items;
  final TextStyle termStyle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final (:term, :link) in items)
        DecoratedBox(
          decoration: _divider,
          child: Padding(
            padding: const EdgeInsets.only(top: 18, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Text(term, style: termStyle),
                link,
              ],
            ),
          ),
        ),
    ],
  );
}

@ReadingPreview('LinkList')
Widget linkListPreview() => const LinkList([
  (term: 'EMAIL', link: TextLink('[address]')),
  (term: 'LINKEDIN', link: TextLink('[profile]')),
  (term: 'CV', link: TextLink('[Download the CV, PDF]')),
]);
