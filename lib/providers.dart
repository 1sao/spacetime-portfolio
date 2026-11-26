import 'package:riverpod/riverpod.dart';

import 'content/content.dart';
import 'content/site_content.dart';
import 'space/system/body.dart';
import 'space/system/system.dart';

final sectionsProvider = Provider<List<Section>>((ref) => sections);

final bodiesProvider = Provider<Map<SectionId, Body>>((ref) => bodies);

final bodiesInPageOrderProvider = Provider<List<Body>>((ref) {
  final sections = ref.watch(sectionsProvider);
  final bodies = ref.watch(bodiesProvider);
  return [for (final section in sections) ?bodies[section.id]];
});
