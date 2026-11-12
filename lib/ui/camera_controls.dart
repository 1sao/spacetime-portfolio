import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../navigation/map_navigation_state.dart';
import '../navigation/navigation.dart';
import '../scene/scene_running.dart';

/// The turn of the camera for each logical pixel of drag, in rad.
const _turnPerDragPixel = 0.006;

/// The zoom for each logical pixel of scroll.
const _zoomPerScrollPixel = 0.001;

/// Turns and zooms the camera at rest.
///
/// A drag with the primary mouse button or one finger turns the camera. The
/// wheel, a trackpad pinch or a two-finger pinch zooms it. The cursor shows
/// if a drag can turn the camera.
///
/// A drag on [overlay] does not turn the camera, but the wheel and a
/// trackpad pinch zoom it there too.
class CameraControls extends ConsumerStatefulWidget {
  const CameraControls({super.key, required this.scene, required this.overlay});

  /// The scene, below the controls.
  final Widget scene;

  /// The widgets on top of the scene, such as buttons.
  final Widget overlay;

  @override
  ConsumerState<CameraControls> createState() => _CameraControlsState();
}

class _CameraControlsState extends ConsumerState<CameraControls> {
  /// True while the primary button or a finger is down on the scene.
  bool _isPressed = false;

  /// The scale of the pinch at the last update. A pinch gives its scale
  /// from its start, and the camera zooms by the change since the last
  /// update.
  double _lastScale = 1;

  void _startPinch(ScaleStartDetails details) => _lastScale = 1;

  /// A drag turns the camera. With two fingers, the change of the pinch
  /// also zooms it.
  void _turnAndPinch(ScaleUpdateDetails details) {
    if (!ref.read(isSceneRunningProvider)) return;
    final navigation = ref.read(navigationProvider.notifier);
    navigation.turn(
      yaw: -details.focalPointDelta.dx * _turnPerDragPixel,
      pitch: details.focalPointDelta.dy * _turnPerDragPixel,
    );
    if (details.pointerCount > 1) {
      navigation.zoom(_lastScale / details.scale);
      _lastScale = details.scale;
    }
  }

  void _zoom(PointerSignalEvent event) {
    if (!ref.read(isSceneRunningProvider)) return;
    final navigation = ref.read(navigationProvider.notifier);
    switch (event) {
      case PointerScrollEvent(:final scrollDelta):
        navigation.zoom(math.exp(scrollDelta.dy * _zoomPerScrollPixel));
      // A trackpad pinch in a browser.
      case PointerScaleEvent(:final scale):
        navigation.zoom(1 / scale);
      default:
    }
  }

  void _setPressed(bool isPressed) {
    if (_isPressed != isPressed) setState(() => _isPressed = isPressed);
  }

  @override
  Widget build(BuildContext context) {
    final isFlying = ref.watch(
      navigationProvider.select((state) => state is InFlight),
    );
    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent || event is PointerScaleEvent) {
          // The registered callback takes the event, so the browser does
          // not also scroll the page or go back in history.
          GestureBinding.instance.pointerSignalResolver.register(event, _zoom);
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.scene,
          MouseRegion(
            cursor: switch (true) {
              _ when isFlying => SystemMouseCursors.basic,
              _ when _isPressed => SystemMouseCursors.grabbing,
              _ => SystemMouseCursors.grab,
            },
            child: Listener(
              onPointerDown: (event) {
                if (event.buttons.isPrimaryButton) _setPressed(true);
              },
              onPointerUp: (_) => _setPressed(false),
              onPointerCancel: (_) => _setPressed(false),
              child: RawGestureDetector(
                behavior: HitTestBehavior.opaque,
                gestures: {
                  ScaleGestureRecognizer:
                      GestureRecognizerFactoryWithHandlers<
                        ScaleGestureRecognizer
                      >(
                        () => ScaleGestureRecognizer(
                          allowedButtonsFilter: (buttons) =>
                              buttons.isPrimaryButton,
                        ),
                        (recognizer) => recognizer
                          ..onStart = _startPinch
                          ..onUpdate = _turnAndPinch,
                      ),
                },
                child: const SizedBox.expand(),
              ),
            ),
          ),
          widget.overlay,
        ],
      ),
    );
  }
}

extension on int {
  /// Only the primary mouse button, or a finger, turns the camera. A right
  /// click opens the browser's menu.
  bool get isPrimaryButton => this == kPrimaryButton;
}
