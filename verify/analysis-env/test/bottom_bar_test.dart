// Widget-level checks for the Bilibili-style bottom bar with the centre action.
//
// Lives in the analysis environment so `flutter test` can run without the app's
// media-kit git dependencies. It imports the real production widget by path.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/app/workspace_bottom_bar.dart';

void main() {
  WorkspaceBottomBarItem item(String id, String label, {bool selected = false}) =>
      WorkspaceBottomBarItem(
        id: id,
        label: label,
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
        selected: selected,
        onSelected: () {},
      );

  testWidgets('centre action is always rendered', (tester) async {
    var created = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: WorkspaceBottomBar(
            items: [item('home', '首页'), item('dynamic', '动态')],
            createLabel: '创作',
            onCreate: () => created++,
            immersive: false,
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('workspace-bottom-create')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('workspace-bottom-create')));
    await tester.pump();
    expect(created, 1);
  });

  testWidgets('destinations keep their stable keys and callbacks', (tester) async {
    final taps = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: WorkspaceBottomBar(
            items: [
              WorkspaceBottomBarItem(
                id: 'home',
                label: '首页',
                icon: Icons.home_outlined,
                selectedIcon: Icons.home_rounded,
                selected: true,
                onSelected: () => taps.add('home'),
              ),
              WorkspaceBottomBarItem(
                id: 'mine',
                label: '我的',
                icon: Icons.person_outline_rounded,
                selectedIcon: Icons.person_rounded,
                selected: false,
                onSelected: () => taps.add('mine'),
              ),
            ],
            createLabel: '创作',
            onCreate: () {},
            immersive: false,
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('workspace-bottom-home')), findsOneWidget);
    expect(find.byKey(const ValueKey('workspace-bottom-mine')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('workspace-bottom-mine')));
    await tester.pump();
    expect(taps, ['mine']);
  });
}
