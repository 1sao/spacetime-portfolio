import 'package:flutter/rendering.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../content/content.dart';
import '../providers.dart';
import '../viewport/window_size.dart';
import 'colors.dart';
import 'corners.dart';
import 'enamel.dart';
import 'hooks.dart';
import 'previews.dart';
import 'sections/about_section.dart';
import 'sections/contact_section.dart';
import 'sections/credits_section.dart';
import 'sections/personal_section.dart';
import 'sections/work_section.dart';
import 'spacing.dart';

class ReadingScreen extends HookConsumerWidget {
  const ReadingScreen({super.key});

  static double panelLeft(double windowWidth) =>
      SiteSpacing.gutter + (0.02 * windowWidth).clamp(0.0, 32.0);

  static double panelWidth(double windowWidth) =>
      (0.56 * windowWidth).clamp(470.0, 860.0);

  static double landingPeekHeight(WidthClass widthClass) =>
      widthClass == WidthClass.expanded ? 116 : 92;

  static const _riseHeight = 6.0;
  static const _aboutMargin = 40.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final window = ref.watch(windowSizeProvider);
    final sectionKeys = useMemoized(
      () => {
        for (final id in SectionId.values) id: GlobalKey(debugLabel: id.name),
      },
    );
    final scroll = Scrollable.of(context).position;
    final isLanding = useIsScrolledToTop();
    final rise = useAnimationController(
      duration: const Duration(milliseconds: 350),
      upperBound: _riseHeight,
    );
    final isMotionReduced = MediaQuery.disableAnimationsOf(context);

    void riseTo(double target) =>
        rise.animateTo(target, curve: Curves.easeOutExpo);

    // Removing the cover does not call its onExit.
    useEffect(() {
      if (!isLanding) riseTo(0);
      return null;
    }, [isLanding]);

    void scrollToAbout() {
      final about = sectionKeys[SectionId.about]!.currentContext!
          .findRenderObject()!;
      // The risen screen drops back once the page scrolls, and About with it.
      final target =
          RenderAbstractViewport.of(about).getOffsetToReveal(about, 0).offset +
          rise.value -
          _aboutMargin;
      // Unlike other animations, a scroll does not shorten with reduced motion.
      if (isMotionReduced) {
        scroll.jumpTo(target);
      } else {
        scroll.animateTo(
          target,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOutCubic,
        );
      }
    }

    final sections = [
      for (final section in ref.watch(sectionsProvider))
        KeyedSubtree(key: sectionKeys[section.id], child: section.id.widget),
    ];
    final cover = isLanding
        ? _LandingCover(
            onHover: (isHovered) => riseTo(isHovered ? _riseHeight : 0),
            onTap: scrollToAbout,
          )
        : null;
    return AnimatedBuilder(
      animation: rise,
      builder: (context, child) =>
          Transform.translate(offset: Offset(0, -rise.value), child: child),
      child: RepaintBoundary(
        child: window.widthClass == WidthClass.expanded
            ? _Panel(window: window, sections: sections, cover: cover)
            : _Cards(window: window, sections: sections, cover: cover),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.window,
    required this.sections,
    required this.cover,
  });

  final WindowSize window;
  final List<Widget> sections;
  final Widget? cover;

  static const _dividerToHeading = 72.0;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      left: ReadingScreen.panelLeft(window.width),
      bottom: SiteSpacing.gutter,
    ),
    child: Align(
      alignment: Alignment.topLeft,
      child: _Selectable(
        cover: cover,
        child: Container(
          width: ReadingScreen.panelWidth(window.width),
          padding: const EdgeInsets.fromLTRB(
            SiteSpacing.readerPad,
            30,
            SiteSpacing.readerPad,
            80,
          ),
          decoration: const EnamelDecoration.panel(
            borderRadius: SiteCorners.screen,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (index, section) in sections.indexed) ...[
                if (index > 0) ...[
                  const SizedBox(height: SiteSpacing.sectionGap),
                  const ColoredBox(
                    color: SiteColors.dividerLine,
                    child: SizedBox(height: SiteSpacing.hairline),
                  ),
                  const SizedBox(height: _dividerToHeading),
                ],
                section,
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

class _Cards extends StatelessWidget {
  const _Cards({
    required this.window,
    required this.sections,
    required this.cover,
  });

  final WindowSize window;
  final List<Widget> sections;
  final Widget? cover;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      SiteSpacing.gutter,
      0,
      SiteSpacing.gutter,
      SiteSpacing.gutter,
    ),
    child: _Selectable(
      cover: cover,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 0.3 * window.smallHeight,
        children: [
          for (final section in sections)
            Container(
              padding: const EdgeInsets.fromLTRB(22, 26, 22, 36),
              decoration: const EnamelDecoration.panel(
                borderRadius: SiteCorners.cardPhone,
              ),
              child: section,
            ),
        ],
      ),
    ),
  );
}

/// A [SelectionArea] takes the clicks and drags on everything in it, so
/// [cover] lies outside it.
class _Selectable extends StatelessWidget {
  const _Selectable({required this.cover, required this.child});

  final Widget? cover;
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      SelectionArea(child: child),
      if (cover case final cover?) Positioned.fill(child: cover),
    ],
  );
}

/// A click on the peek goes to About and selects no text. The cover
/// handles only taps, so a swipe on it still scrolls the page.
class _LandingCover extends StatelessWidget {
  const _LandingCover({required this.onHover, required this.onTap});

  final ValueChanged<bool> onHover;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => onHover(true),
    onExit: (_) => onHover(false),
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onTap: onTap,
    ),
  );
}

extension on SectionId {
  Widget get widget => switch (this) {
    SectionId.about => const AboutSection(),
    SectionId.work => const WorkSection(),
    SectionId.personal => const PersonalSection(),
    SectionId.contact => const ContactSection(),
    SectionId.credits => const CreditsSection(),
  };
}

@PagePreview('ReadingScreen')
Widget readingScreenPreview() => const ReadingScreen();
