import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vector_math/vector_math_64.dart' show Vector2;

import '../content/content.dart';
import '../navigation/map_location.dart';
import '../navigation/map_navigation_state.dart';
import '../navigation/navigation.dart';
import '../providers.dart';
import '../scene/frame_loop.dart';
import '../scene/scene_running.dart';
import '../space/camera.dart';
import '../space/frame_snapshot.dart';
import '../space/pick.dart';

/// The turn of the camera for each logical pixel of drag, in rad.
const _turnPerDragPixel = 0.006;

/// The zoom for each logical pixel of scroll.
const _zoomPerScrollPixel = 0.001;

/// Turns and zooms the camera at rest, and goes to a body's category when
/// the visitor taps the body.
///
/// A drag with the primary mouse button or one finger turns the camera. The
/// wheel, a trackpad pinch or a two-finger pinch zooms it. The cursor shows
/// if a drag can turn the camera, or if a click goes to a body.
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
  bool get _isSceneRunning => ref.read(isSceneRunningProvider);

  Navigation get _navigation => ref.read(navigationProvider.notifier);

  List<Category> get _categories => ref.read(contentProvider);

  /// True while the primary button or a finger is down on the scene.
  bool _isPressed = false;

  /// True while the mouse is over a body, so a click goes to it.
  bool _isOverBody = false;

  /// The scale of the pinch at the last update. A pinch gives its scale
  /// from its start, and the camera zooms by the change since the last
  /// update.
  double _lastScale = 1;

  /// The fingers that are down on the scene.
  final Set<int> _fingersDown = {};

  /// True from the time a gesture has two fingers until every finger is
  /// up. A finger that stays down after a pinch does not turn the camera:
  /// it often slides a little as the visitor lifts it.
  bool _hasPinched = false;

  void _startPinch(ScaleStartDetails details) => _lastScale = 1;

  /// A drag turns the camera. With two fingers, the change of the pinch
  /// also zooms it.
  void _turnAndPinch(ScaleUpdateDetails details) {
    if (!_isSceneRunning) return;
    if (details.pointerCount > 1) _hasPinched = true;
    if (_hasPinched && details.pointerCount == 1) return;
    _navigation.turn(
      yaw: -details.focalPointDelta.dx * _turnPerDragPixel,
      pitch: details.focalPointDelta.dy * _turnPerDragPixel,
    );
    if (details.pointerCount > 1) {
      _navigation.zoom(_lastScale / details.scale);
      _lastScale = details.scale;
    }
  }

  void _zoom(PointerSignalEvent event) {
    if (!_isSceneRunning) return;
    switch (event) {
      case PointerScrollEvent(:final scrollDelta):
        _navigation.zoom(math.exp(scrollDelta.dy * _zoomPerScrollPixel));
      // A trackpad pinch in a browser.
      case PointerScaleEvent(:final scale):
        _navigation.zoom(1 / scale);
      default:
    }
  }

  void _goToBody(CategoryLocation? location) {
    if (!_isSceneRunning || location == null) return;
    // The body flies away from under the mouse.
    _setOverBody(false);
    context.go(location.path);
  }

  void _setOverBody(bool isOverBody) {
    if (_isOverBody != isOverBody) setState(() => _isOverBody = isOverBody);
  }

  void _liftFinger(PointerEvent event) {
    _fingersDown.remove(event.pointer);
    if (_fingersDown.isEmpty) _hasPinched = false;
  }

  void _setPressed(bool isPressed) {
    if (_isPressed != isPressed) setState(() => _isPressed = isPressed);
  }

  /// The cursor shows if a click goes to a body, if a drag can turn the
  /// camera, and if it turns it now.
  MouseCursor _cursor({required bool isFlying}) {
    if (_isOverBody) return SystemMouseCursors.click;
    if (_isPressed) {
      return isFlying ? SystemMouseCursors.basic : SystemMouseCursors.grabbing;
    }
    if (isFlying) return SystemMouseCursors.basic;
    return SystemMouseCursors.grab;
  }

  @override
  Widget build(BuildContext context) {
    // Watched, so the frame loop lives while the pick reads its frames.
    final currentFrame = ref.watch(frameSnapshotListenableProvider);

    // TODO(owner): the bodies move under a still mouse, and the cursor only
    // changes on the next mouse move. Pick again on each frame while the
    // mouse is over the scene.
    void updateOverBody(Offset position) => _setOverBody(
      currentFrame.value.categoryAt(
            position,
            size: context.size!,
            categories: _categories,
          ) !=
          null,
    );

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
            cursor: _cursor(isFlying: isFlying),
            onHover: (event) => updateOverBody(event.localPosition),
            onExit: (_) => _setOverBody(false),
            child: Listener(
              onPointerDown: (event) {
                if (event.kind == PointerDeviceKind.touch) {
                  _fingersDown.add(event.pointer);
                }
                if (event.buttons.isPrimaryButton) _setPressed(true);
              },
              // No hover events come during a drag, and the body under the
              // mouse can change.
              onPointerUp: (event) {
                _liftFinger(event);
                _setPressed(false);
                if (event.kind == PointerDeviceKind.mouse) {
                  updateOverBody(event.localPosition);
                }
              },
              onPointerCancel: (event) {
                _liftFinger(event);
                _setPressed(false);
              },
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
                  // A tap wins against the drag if the pointer moves less
                  // than the tap's slop.
                  TapGestureRecognizer:
                      GestureRecognizerFactoryWithHandlers<
                        TapGestureRecognizer
                      >(
                        () => TapGestureRecognizer(
                          allowedButtonsFilter: (buttons) =>
                              buttons.isPrimaryButton,
                        ),
                        (recognizer) =>
                            recognizer
                              ..onTapUp = (details) => _goToBody(
                                currentFrame.value.categoryAt(
                                  details.localPosition,
                                  size: context.size!,
                                  categories: _categories,
                                ),
                              ),
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

extension on FrameSnapshot {
  /// The category of the body at [position] of a scene of [size], in
  /// logical pixels from its top left, or null if there is none. The
  /// bodies are in the order of [categories].
  CategoryLocation? categoryAt(
    Offset position, {
    required Size size,
    required List<Category> categories,
  }) {
    final picked = pickBody(
      this,
      Vector2(position.dx, position.dy),
      Screen(width: size.width, height: size.height),
    );
    return picked == null ? null : CategoryLocation(categories[picked]);
  }
}

extension on int {
  /// Only the primary mouse button, or a finger, turns the camera. A right
  /// click opens the browser's menu.
  bool get isPrimaryButton => this == kPrimaryButton;
}
