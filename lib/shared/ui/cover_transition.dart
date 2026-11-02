import 'package:flutter/material.dart';

import 'cover_flight.dart';

/// 封面 ↔ 播放页 的对称容器转场入口。
///
/// 本应用没有路由级转场（`/video/:bvid` 的 GoRoute 只返回 `SizedBox.shrink()`，
/// 页面由工作区外壳自己挂载与切换），所以转场必须挂在**外壳切页**这一层：
/// 卡片点击时先登记「起点 + 封面」，外壳切到播放页后播放前进动画，
/// 关闭播放页时用同一份登记反跑一次，落点就是封面原来的矩形。
///
/// 为什么要静态登记而不是把矩形一路传下去：点击 → 控制器 → Provider → 外壳
/// 这条链上没有统一的参数通道，硬塞会把业务参数污染；这里只保留一份
/// 「最近一次点击」的转场上下文，超过 [freshness] 自动失效，避免陈旧矩形被误用。
final class CoverTransition {
  CoverTransition._();

  /// 登记有效期：超过这个时间的登记视为无效（用户点了封面却没进播放页）。
  static const Duration freshness = Duration(seconds: 2);

  /// 前进动画时长，与 [CoverFlight.forwardDuration] 保持一致。
  static const Duration forwardDuration = CoverFlight.forwardDuration;

  static _Pending? _pending;

  /// 在封面点击处调用：记录封面当前矩形与用于过渡的画面。
  ///
  /// [cover] 必须是能立即绘制的封面（通常复用卡片里同一个图片组件），
  /// 过渡层会在它外面套圆角裁剪。
  static void capture(
    BuildContext context, {
    required Widget cover,
    double cornerRadius = 6,
  }) {
    final rect = captureFlightRect(context, cornerRadius: cornerRadius);
    if (rect == null) {
      _pending = null;
      return;
    }
    _pending = _Pending(
      from: rect,
      cover: cover,
      cornerRadius: cornerRadius,
      at: DateTime.now(),
    );
  }

  /// 前进：外壳切到播放页后调用，从封面矩形展开到整屏。
  ///
  /// 返回 true 表示确实播放了动画（有有效登记）。
  static bool playForward(BuildContext context) {
    final pending = _take();
    if (pending == null) return false;
    final size = MediaQuery.sizeOf(context);
    CoverFlight.run(
      context: context,
      from: pending.from,
      to: Offset.zero & size,
      child: pending.cover,
      fromRadius: BorderRadius.circular(pending.cornerRadius),
    );
    // 收起时要用同一份起点，这里重新挂回一个「最近一次」记录。
    _last = pending;
    return true;
  }

  /// 反向：关闭播放页时调用，从整屏收回到封面原矩形。
  ///
  /// 与 [playForward] 用同一组参数反向跑，因此视觉上沿同一条路径返回。
  static bool playBack(BuildContext context) {
    final last = _last;
    if (last == null) return false;
    if (DateTime.now().difference(last.at) > const Duration(minutes: 2)) {
      _last = null;
      return false;
    }
    final size = MediaQuery.sizeOf(context);
    CoverFlight.run(
      context: context,
      from: Offset.zero & size,
      to: last.from,
      child: last.cover,
      fromRadius: BorderRadius.zero,
      toRadius: BorderRadius.circular(last.cornerRadius),
      duration: CoverFlight.reverseDuration,
      curve: CoverFlight.reverseCurve,
    );
    _last = null;
    return true;
  }

  static _Pending? _last;

  /// 丢弃登记（例如导航失败、或用户又点了别处）。
  static void clear() {
    _pending = null;
    _last = null;
  }

  static _Pending? _take() {
    final pending = _pending;
    _pending = null;
    if (pending == null) return null;
    if (DateTime.now().difference(pending.at) > freshness) return null;
    return pending;
  }
}

final class _Pending {
  const _Pending({
    required this.from,
    required this.cover,
    required this.cornerRadius,
    required this.at,
  });

  final Rect from;
  final Widget cover;
  final double cornerRadius;
  final DateTime at;
}
