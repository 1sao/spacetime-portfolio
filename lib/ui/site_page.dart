import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../debug/fps_counter.dart';
import '../scene/scene_view.dart';
import '../viewport/window_size.dart';
import 'landing.dart';
import 'reading_screen.dart';

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
          const SingleChildScrollView(
            child: Column(children: [Landing(), ReadingScreen()]),
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
