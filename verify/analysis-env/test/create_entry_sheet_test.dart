// Checks the centre action's entry chooser: both creation flows are offered
// and choosing one returns its identity to the caller.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/features/create/domain/create_entry.dart';
import '../../../lib/features/create/presentation/create_entry_sheet.dart';

void main() {
  testWidgets('sheet offers video and article', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CreateEntrySheet())),
    );
    expect(find.byKey(const ValueKey('create-entry-video')), findsOneWidget);
    expect(find.byKey(const ValueKey('create-entry-article')), findsOneWidget);
    expect(find.text('视频'), findsOneWidget);
    expect(find.text('图文'), findsOneWidget);
  });

  testWidgets('tapping an entry pops it back to the caller', (tester) async {
    CreateEntry? chosen;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(onPressed: () async { chosen = await showCreateEntrySheet(context); }, child: const Text('open')),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('create-entry-sheet')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('create-entry-article')));
    await tester.pumpAndSettle();
    expect(chosen, CreateEntry.article);
  });
}
