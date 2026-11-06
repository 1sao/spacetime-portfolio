import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../providers.dart';

/// Every category and message as plain text, for anyone who doesn't want to
/// fly.
class ListPage extends ConsumerWidget {
  const ListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(contentProvider);
    final type = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: SizedBox(
              width: 640,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton(
                    onPressed: () => context.go('/'),
                    child: const Text('Map'),
                  ),
                  for (final category in content) ...[
                    const SizedBox(height: 32),
                    _Heading(
                      category.name,
                      level: 2,
                      style: type.headlineSmall,
                    ),
                    for (final message in category.messages) ...[
                      const SizedBox(height: 16),
                      _Heading(
                        message.title,
                        level: 3,
                        style: type.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(message.text, style: type.bodyMedium),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text, {required this.level, this.style});

  final String text;
  final int level;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      headingLevel: level,
      child: Text(text, style: style),
    );
  }
}
