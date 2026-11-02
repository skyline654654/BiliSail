import 'package:flutter/material.dart';

import '../domain/create_entry.dart';

/// Shows the entry chooser for the centre action.
///
/// Returns the chosen entry, or null when the sheet is dismissed. The sheet only
/// picks a flow; [CreateScreen] owns the form and the submission.
Future<CreateEntry?> showCreateEntrySheet(BuildContext context) {
  return showModalBottomSheet<CreateEntry>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) => const CreateEntrySheet(),
  );
}

/// The two large tiles Bilibili puts behind its centre plus.
class CreateEntrySheet extends StatelessWidget {
  const CreateEntrySheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '创作',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.start,
              ),
            ),
            for (final entry in CreateEntry.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _CreateEntryTile(entry: entry),
              ),
          ],
        ),
      ),
    );
  }
}

class _CreateEntryTile extends StatelessWidget {
  const _CreateEntryTile({required this.entry});

  final CreateEntry entry;

  IconData get _icon => switch (entry) {
    CreateEntry.video => Icons.videocam_rounded,
    CreateEntry.article => Icons.article_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: ValueKey('create-entry-${entry.name}'),
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).pop(entry),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_icon, color: colors.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      entry.label,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.description,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
