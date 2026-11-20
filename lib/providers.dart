import 'package:riverpod/riverpod.dart';

import 'content/content.dart';
import 'content/site_content.dart';
import 'space/body.dart';
import 'space/system.dart';

final contentProvider = Provider<List<Section>>((ref) => sections);

/// The body of each section that has one.
final bodiesProvider = Provider<Map<SectionId, Body>>((ref) => bodies);
