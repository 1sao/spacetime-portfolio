import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../debug/fps_counter.dart';
import '../scene/scene_view.dart';
import 'reading_screen.dart';
import 'spacing.dart';

/// The site's one page: the scene fills the window and stays fixed, and the
/// page scrolls over it. The Landing fills the first screen, except for a
/// strip at the bottom, where the top of the reading screen shows.
class SitePage extends StatelessWidget {
  const SitePage({super.key});

  static const path = '/';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: SceneView()),
          LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                    height: math.max(
                      0,
                      constraints.maxHeight - SiteSpacing.peek,
                    ),
                  ),
                  const ReadingScreen(),
                ],
              ),
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
