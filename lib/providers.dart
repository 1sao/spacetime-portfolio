// The pure-Dart package, so `navigation/` can import this file.
import 'package:riverpod/riverpod.dart';

import 'content/content.dart';
import 'content/site_content.dart';

final contentProvider = Provider<List<Category>>((ref) => categories);
