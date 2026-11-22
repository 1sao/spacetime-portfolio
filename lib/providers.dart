import 'package:riverpod/riverpod.dart';

import 'content/content.dart';
import 'content/site_content.dart';
import 'space/body.dart';
import 'space/system.dart';

final contentProvider = Provider<List<Section>>((ref) => sections);

/// The body of each section that has one.
final bodiesProvider = Provider<Map<SectionId, Body>>((ref) => bodies);

/// The bodies in page order, which gives each its slot in the shader.
final bodiesInPageOrderProvider = Provider<List<Body>>((ref) {
  final content = ref.watch(contentProvider);
  final bodies = ref.watch(bodiesProvider);
  return [for (final section in content) ?bodies[section.id]];
});
