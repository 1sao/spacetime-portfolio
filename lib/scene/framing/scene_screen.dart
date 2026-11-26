import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../space/camera/camera.dart';
import '../../viewport/window_size.dart';

final sceneScreenProvider = Provider<Screen>((ref) {
  // The large height keeps the scene's size while the address bar hides.
  final (:width, :height) = ref.watch(
    windowSizeProvider.select(
      (window) => (width: window.width, height: window.largeHeight),
    ),
  );
  return Screen(width: width, height: height);
});
