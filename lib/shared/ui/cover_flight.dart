import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Route-agnostic「封面 → 播放页」容器转场。
///
/// 为什么不用 `Hero`：本应用的路由只是深链占位（`/video/:bvid` 的 GoRoute 只返回
/// `SizedBox.shrink()`），真正的页面由工作区外壳自己保留与切换，切换不是
/// `Navigator.push`。`Hero` 的飞行发生在同一 Navigator 的两条路由之间，
/// 因此在这个外壳里不会触发。
///
/// 这里改用 Overlay 承载过渡载体：目标页面照常先挂载（视频已经在播），
/// 过渡层盖在上面把封面从起点矩形非线性推到终点矩形，结束即移除。
/// 优点：
/// - 不要求两条路由，外壳的页面保留/返回历史完全不受影响；
/// - 起点矩形由调用方在点击那一刻采样，天然满足“从封面当前位置开始”；
/// - 正反向共用同一套参数，收起时反向跑即可精确落回。
final class CoverFlight {
  CoverFlight._({
    required this.entry,
    required this.controller,
    required this.animation,
  });

  final OverlayEntry entry;
  final AnimationController controller;
  final CurvedAnimation animation;

  /// 在 [context] 所在的 Overlay 上播放一次转场。
  ///
  /// [from] 必须是点击瞬间封面在**全局坐标**下的矩形（`RenderBox.localToGlobal`
  /// 加上自身的 `size`）；[to] 是播放画面最终占据的矩形。
  /// [child] 是过渡载体本身（通常是封面图，和播放器首帧未就绪时叠在一起）。
  static CoverFlight run({
    required BuildContext context,
    required Rect from,
    required Rect to,
    required Widget child,
    BorderRadius fromRadius = const BorderRadius.all(Radius.circular(6)),
    BorderRadius toRadius = BorderRadius.zero,
    Duration duration = forwardDuration,
    Curve curve = forwardCurve,
    Widget Function(BuildContext context, Widget child)? decorate,
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    // 系统要求减弱动效时不做位移，直接一帧到位，避免眩晕。
    final animate = !MediaQuery.disableAnimationsOf(context);

    late final CoverFlight flight;
    final controller = AnimationController(
      vsync: overlay,
      duration: animate ? duration : Duration.zero,
    );
    final animation = CurvedAnimation(
      parent: controller,
      curve: curve,
      reverseCurve: reverseCurve,
    );

    final entry = OverlayEntry(
      builder: (overlayContext) {
        final t = animation.value;
        final rect = _easedLerpRect(from, to, t);
        // 圆角跟着几何一起插值，避免展开中途出现“方角封面”。
        final radius = BorderRadius.lerp(fromRadius, toRadius, t) ?? fromRadius;
        return IgnorePointer(
          child: Stack(
            children: [
              Positioned(
                left: rect.left,
                top: rect.top,
                width: rect.width,
                height: rect.height,
                // 独立图层：转场期间的模糊/阴影重绘不会连带整屏。
                child: RepaintBoundary(
                  child: ClipRRect(
                    borderRadius: radius,
                    child: decorate == null ? child : decorate(overlayContext, child),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    flight = CoverFlight._(entry: entry, controller: controller, animation: animation);
    overlay.insert(entry);
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        if (entry.mounted) entry.remove();
      }
    });
    controller.forward();
    return flight;
  }

  /// 中途反向收起。若动画未走完就要求返回，从**当前位置**反向，
  /// 而不是先跳回终点再收，视觉上才连贯。
  Future<void> reverse({Duration? duration}) async {
    if (duration != null) controller.duration = duration;
    await controller.reverse();
    if (entry.mounted) entry.remove();
  }

  /// 立即移除过渡层（例如目标页在飞行途中被关闭）。
  void dispose() {
    if (entry.mounted) entry.remove();
    controller.dispose();
  }

  /// 展开默认 420ms：封面到全屏跨度大，300ms 会显得“抢”。
  static const Duration forwardDuration = Duration(milliseconds: 420);

  /// 收起略快，符合“离开比进入干脆”的体感。
  static const Duration reverseDuration = Duration(milliseconds: 320);

  static const Curve forwardCurve = Curves.easeOutQuint;
  static const Curve reverseCurve = Curves.easeInCubic;

  /// 对外暴露的几何插值：便于单测断言“单调且非线性”。
  static Rect easedRect(Rect from, Rect to, double t) => _easedLerpRect(from, to, t);

  /// 在曲线上再叠一层缓动，让中段更快、末段更稳（非匀速拉伸）。
  static Rect _easedLerpRect(Rect from, Rect to, double t) {
    final eased = Curves.fastOutSlowIn.transform(t.clamp(0.0, 1.0));
    return Rect.lerp(from, to, eased) ?? (t < 0.5 ? from : to);
  }
}

/// 采集某个组件当前在屏幕上的矩形与圆角，作为转场起点。
///
/// 返回 null 表示组件尚未布局（例如列表还在构建），调用方应退回无动画跳转。
Rect? captureFlightRect(BuildContext context, {double cornerRadius = 6}) {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.hasSize || !box.attached) return null;
  final origin = box.localToGlobal(Offset.zero);
  final rect = origin & box.size;
  final screen = MediaQuery.maybeSizeOf(context);
  if (screen == null) return rect;
  // 封面被滚动到视口外时只保留可见部分，否则会出现“从屏幕外飞入”。
  final visible = rect.intersect(Offset.zero & screen);
  if (visible.isEmpty) return null;
  return visible;
}

/// 供目标页判断“首帧是否已就绪”，决定过渡层里封面的淡出时机。
///
/// 目标页在播放器首帧到达时调用 [markReady]；过渡层用 [opacityFor]
/// 在最后 40% 行程里把封面淡出，露出已经在播的画面。
final class CoverFlightReveal extends ChangeNotifier {
  bool _ready = false;

  bool get isReady => _ready;

  void markReady() {
    if (_ready) return;
    _ready = true;
    notifyListeners();
  }

  /// 封面在图上的不透明度：首帧未就绪时全程 1；就绪后从 0.6 行程开始淡出。
  double opacityFor(double progress) {
    if (!_ready) return 1;
    final tail = ((progress - 0.6) / 0.4).clamp(0.0, 1.0);
    return 1 - tail;
  }

  /// 供过渡层在动画里读取圆角衰减后的封面透明度（保留接口，便于接入播放器）。
  double opacityAt(double progress) => math.max(0, math.min(1, opacityFor(progress)));
}