import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../content/content.dart';
import '../providers.dart';
import '../scene/framing/reading_screen_geometry.dart';
import '../scene/render/opaque_surface.dart';
import '../viewport/reading_panel.dart';
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
  const ReadingScreen({
    super.key,
    required this.opaqueSurfaces,
    required this.pageHeight,
  });

  final OpaqueSurfaceRegistry opaqueSurfaces;

  /// The page measures itself again when it changes.
  final ValueListenable<double?> pageHeight;

  static double landingPeekHeight(SectionLayout layout) => switch (layout) {
    SectionLayout.panel => 116,
    SectionLayout.cards => 92,
  };

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

    // The scroll offsets at which [section]'s top and bottom reach the top
    // of the view, without the lift that a hover gives the reading screen.
    SectionSpan spanOf(SectionId section) {
      final box =
          sectionKeys[section]!.currentContext!.findRenderObject()!
              as RenderBox;
      final top =
          RenderAbstractViewport.of(box).getOffsetToReveal(box, 0).offset +
          rise.value;
      return (top: top, bottom: top + box.size.height);
    }

    final geometryNotifier = ref.read(
      measuredReadingScreenGeometryProvider.notifier,
    );
    void measurePage() {
      if (!context.mounted) return;
      geometryNotifier.geometry = ReadingScreenGeometry(
        sections: [
          for (final section in ref.read(sectionsProvider)) spanOf(section.id),
        ],
        // As with the address bar hidden, so the track stays put when the
        // bar moves.
        maxScroll: math.max(
          0,
          scroll.maxScrollExtent +
              scroll.viewportDimension -
              window.largeHeight,
        ),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => measurePage());
    // Without a page, the frame loop has no scroll to read.
    useEffect(() => geometryNotifier.clear, const []);
    useEffect(() {
      pageHeight.addListener(measurePage);
      return () => pageHeight.removeListener(measurePage);
    }, [pageHeight, window]);

    void riseTo(double target) =>
        rise.animateTo(target, curve: Curves.easeOutExpo);

    // Removing the cover does not call its onExit.
    useEffect(() {
      if (!isLanding) riseTo(0);
      return null;
    }, [isLanding]);

    void scrollToAbout() {
      final target = spanOf(SectionId.about).top - _aboutMargin;
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
        child: window.widthClass.sectionLayout == SectionLayout.panel
            ? _Panel(
                window: window,
                sections: sections,
                cover: cover,
                opaqueSurfaces: opaqueSurfaces,
              )
            : _Cards(
                window: window,
                sections: sections,
                cover: cover,
                opaqueSurfaces: opaqueSurfaces,
              ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.window,
    required this.sections,
    required this.cover,
    required this.opaqueSurfaces,
  });

  final WindowSize window;
  final List<Widget> sections;
  final Widget? cover;
  final OpaqueSurfaceRegistry opaqueSurfaces;

  static const _dividerToHeading = 72.0;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      left: ReadingPanel.of(window.width).left,
      bottom: SiteSpacing.gutter,
    ),
    child: Align(
      alignment: Alignment.topLeft,
      child: _Selectable(
        cover: cover,
        child: _EnamelSurface(
          opaqueSurfaceRegistry: opaqueSurfaces,
          borderRadius: SiteCorners.screen,
          width: ReadingPanel.of(window.width).width,
          padding: const EdgeInsets.fromLTRB(
            SiteSpacing.readerPad,
            30,
            SiteSpacing.readerPad,
            80,
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
    required this.opaqueSurfaces,
  });

  final WindowSize window;
  final List<Widget> sections;
  final Widget? cover;
  final OpaqueSurfaceRegistry opaqueSurfaces;

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
            _EnamelSurface(
              opaqueSurfaceRegistry: opaqueSurfaces,
              borderRadius: SiteCorners.cardPhone,
              padding: const EdgeInsets.fromLTRB(22, 26, 22, 36),
              child: section,
            ),
        ],
      ),
    ),
  );
}

class _EnamelSurface extends StatelessWidget {
  const _EnamelSurface({
    required this.opaqueSurfaceRegistry,
    required this.borderRadius,
    this.width,
    required this.padding,
    required this.child,
  });

  final OpaqueSurfaceRegistry opaqueSurfaceRegistry;
  final BorderRadius borderRadius;
  final double? width;
  final EdgeInsets padding;
  final Widget child;

  @override
  Widget build(BuildContext context) => OpaqueSurface(
    registry: opaqueSurfaceRegistry,
    borderRadius: borderRadius,
    child: Container(
      width: width,
      padding: padding,
      decoration: EnamelDecoration.panel(borderRadius: borderRadius),
      child: child,
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
Widget readingScreenPreview() => ReadingScreen(
  opaqueSurfaces: OpaqueSurfaceRegistry(),
  pageHeight: ValueNotifier(null),
);
