import 'package:flutter/foundation.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../debug/fps_counter.dart';
import '../scene/page_scroll.dart';
import '../scene/render/opaque_surface.dart';
import '../scene/scene_view.dart';
import '../viewport/window_size.dart';
import 'landing.dart';
import 'reading_screen.dart';

class SitePage extends HookConsumerWidget {
  const SitePage({super.key});

  static const path = '/';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final window = ref.watch(windowSizeProvider);
    final opaqueSurfaces = useMemoized(OpaqueSurfaceRegistry.new);
    final pageHeight = useValueNotifier<double?>(null);
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: window.largeHeight,
            child: SceneView(opaqueSurfaces: opaqueSurfaces),
          ),
          NotificationListener<ScrollMetricsNotification>(
            onNotification: (notification) {
              if (notification.depth > 0) return false;
              final metrics = notification.metrics;
              pageHeight.value =
                  metrics.maxScrollExtent + metrics.viewportDimension;
              return false;
            },
            child: SingleChildScrollView(
              controller: ref.watch(pageScrollControllerProvider),
              child: Column(
                children: [
                  const Landing(),
                  ReadingScreen(
                    opaqueSurfaces: opaqueSurfaces,
                    pageHeight: pageHeight,
                  ),
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
