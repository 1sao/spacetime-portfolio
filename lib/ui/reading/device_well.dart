import 'package:material_ui/material_ui.dart';

import '../colours.dart';
import '../enamel.dart';
import '../previews.dart';
import '../spacing.dart';
import '../type.dart';

class DeviceWell extends StatelessWidget {
  const DeviceWell({super.key, required this.caption});

  final String caption;

  @override
  Widget build(BuildContext context) {
    return SelectionContainer.disabled(
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: DecoratedBox(
          decoration: const EnamelDecoration.well(),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(SiteSpacing.gutter),
              child: Text(
                caption,
                textAlign: TextAlign.center,
                style: context.type.entryDetails.copyWith(
                  color: SiteColours.fadedPrint,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

@ReadingPreview('DeviceWell')
Widget deviceWellPreview() => const DeviceWell(caption: '[Device mock]');
