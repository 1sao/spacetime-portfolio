import 'package:material_ui/material_ui.dart';

import '../../content/content.dart';
import '../../content/site_content.dart';
import '../colours.dart';
import '../reading/section_frame.dart';
import '../spacing.dart';
import '../type.dart';

class CreditsSection extends StatelessWidget {
  const CreditsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final style = context.type.body;
    final workStyle = style.copyWith(
      color: SiteColours.lampWhite,
      fontWeight: FontWeight.w600,
    );
    return SectionFrame(
      id: SectionId.credits,
      spacing: SiteSpacing.sm,
      children: [
        for (final credit in credits)
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: credit.workName, style: workStyle),
                TextSpan(text: ' by ${credit.author}, ${credit.licenceName}'),
              ],
            ),
            style: style,
          ),
      ],
    );
  }
}
