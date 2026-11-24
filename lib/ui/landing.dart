import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../scene/scene_layout_provider.dart';
import '../viewport/window_size.dart';
import 'reading/heading.dart';
import 'reading_screen.dart';
import 'spacing.dart';
import 'type.dart';

class Landing extends ConsumerStatefulWidget {
  const Landing({super.key});

  @override
  ConsumerState<Landing> createState() => _LandingState();
}

class _LandingState extends ConsumerState<Landing> {
  final _introKey = GlobalKey();

  static const _bodyTitleHeight = 34.0;
  static const _introMaxWidth = 490.0;
  static const _titleSpaceBelowRow =
      SiteSpacing.titleRow + _bodyTitleHeight + SiteSpacing.titleTier;
  static const _titleSpaceBelowColumn = 30.0;

  @override
  Widget build(BuildContext context) {
    final window = ref.watch(windowSizeProvider);
    final type = context.type;
    final widthClass = window.widthClass;
    final isExpanded = widthClass == WidthClass.expanded;
    final isCompact = widthClass == WidthClass.compact;
    // The intro's height changes with the text size.
    MediaQuery.textScalerOf(context);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _setLandingFloor(isLandingColumn: isCompact),
    );

    return SizedBox(
      height: math.max(
        0,
        window.smallHeight - ReadingScreen.landingPeekHeight(widthClass),
      ),
      child: Stack(
        children: [
          Positioned(
            left: isExpanded
                ? ReadingScreen.panelLeft(window.width) + SiteSpacing.readerPad
                : 20,
            right: isExpanded ? null : 20,
            bottom: isCompact ? 26 : 34,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _introMaxWidth),
              child: Column(
                key: _introKey,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Heading('[Name]', level: 1, style: type.ownerName),
                  const SizedBox(height: 10),
                  Text('ANDROID AND FLUTTER DEVELOPER', style: type.roleLabel),
                  const SizedBox(height: 14),
                  Text('[One welcome sentence.]', style: type.welcome),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _setLandingFloor({required bool isLandingColumn}) {
    if (!mounted) return;
    final intro = _introKey.currentContext!.findRenderObject()! as RenderBox;
    // At scroll 0 the Landing's top is the scene's top.
    final introTop = intro
        .localToGlobal(Offset.zero, ancestor: context.findRenderObject())
        .dy;
    ref.read(landingFloorProvider.notifier).floor =
        introTop -
        (isLandingColumn ? _titleSpaceBelowColumn : _titleSpaceBelowRow);
  }
}
