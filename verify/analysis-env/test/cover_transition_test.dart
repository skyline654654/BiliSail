// 转场登记的语义契约（不启动动画，避免测试里留下 ticker）。
// 动画几何由 cover_flight_test.dart 的纯函数断言覆盖；真实观感需在设备上确认。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/shared/ui/cover_transition.dart';

void main() {
  setUp(CoverTransition.clear);

  testWidgets('没有登记时前进与反向都是空操作', (tester) async {
    late BuildContext appContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            appContext = context;
            return const Scaffold(body: SizedBox.shrink());
          },
        ),
      ),
    );
    expect(CoverTransition.playForward(appContext), isFalse);
    expect(CoverTransition.playBack(appContext), isFalse);
  });

  testWidgets('clear 之后登记失效', (tester) async {
    late BuildContext appContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            appContext = context;
            return const Scaffold(
              body: Center(child: SizedBox(key: Key('c'), width: 120, height: 68)),
            );
          },
        ),
      ),
    );
    final coverContext = tester.element(find.byKey(const Key('c')));
    CoverTransition.capture(coverContext, cover: const SizedBox.shrink());
    CoverTransition.clear();
    expect(CoverTransition.playForward(appContext), isFalse);
  });
}
