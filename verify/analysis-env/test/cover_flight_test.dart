// 转场几何的纯函数断言：起点/终点精确、过程单调、且确实是非线性。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/shared/ui/cover_flight.dart';

void main() {
  const from = Rect.fromLTWH(20, 300, 160, 90);
  const to = Rect.fromLTWH(0, 0, 400, 225);

  test('端点精确命中，不留 1px 误差', () {
    expect(CoverFlight.easedRect(from, to, 0), from);
    expect(CoverFlight.easedRect(from, to, 1), to);
  });

  test('几何单调推进，不存在回弹或跳变', () {
    var lastWidth = from.width - 0.001;
    var lastTop = from.top + 0.001;
    for (var i = 0; i <= 40; i++) {
      final rect = CoverFlight.easedRect(from, to, i / 40);
      expect(rect.width, greaterThanOrEqualTo(lastWidth));
      expect(rect.top, lessThanOrEqualTo(lastTop));
      lastWidth = rect.width;
      lastTop = rect.top;
    }
  });

  test('非线性：旅程中点的几何进度明显偏离线性', () {
    final mid = CoverFlight.easedRect(from, to, 0.25);
    final linearWidth = from.width + (to.width - from.width) * 0.25;
    // 线性插值会正好落在 25% 处；缓动必须偏离它。
    expect((mid.width - linearWidth).abs(), greaterThan(1.0));
  });

  test('首帧未就绪时封面全程不透明', () {
    final reveal = CoverFlightReveal();
    expect(reveal.opacityFor(0.0), 1);
    expect(reveal.opacityFor(0.99), 1);
  });

  test('首帧就绪后封面只在最后 40% 淡出', () {
    final reveal = CoverFlightReveal()..markReady();
    expect(reveal.opacityFor(0.5), 1);
    final late = reveal.opacityFor(0.8);
    expect(late, lessThan(1));
    expect(late, greaterThan(0));
    expect(reveal.opacityFor(1.0), 0);
  });
}
