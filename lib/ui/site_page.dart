import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../debug/fps_counter.dart';
import '../scene/scene_view.dart';
import '../viewport/window_size.dart';
import 'reading_screen.dart';
import 'spacing.dart';

/// The site's one page: the scene fills the screen and stays fixed, and the
/// page scrolls over it. The Landing fills the first screen, except for a
/// strip at the bottom, where the top of the reading screen shows.
///
/// The scene is as tall as the window with the address bar hidden, so
/// while the bar shows, the scene's bottom is below the window's edge. The
/// first screen is as tall as the window with the bar shown, so the strip
/// shows when the page opens (see [WindowSize]).
class SitePage extends ConsumerWidget {
  const SitePage({super.key});

  static const path = '/';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final window = ref.watch(windowSizeProvider);
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: window.largeHeight,
            child: const SceneView(),
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  height: math.max(0, window.smallHeight - SiteSpacing.peek),
                ),
                const ReadingScreen(),
              ],
            ),
          ),
          if (kDebugMode)
            const SafeArea(
              child: Align(alignment: Alignment.topLeft, child: FpsCounter()),
            ),
        ],
      ),
    );
  }
}
