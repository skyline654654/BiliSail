# 封面 → 播放页 容器转场

## 1. 为什么不能直接照搬 Hero

先读代码的结论：**本应用的 go_router 路由只是深链占位**。

```dart
// lib/app/router.dart:178-197
for (final path in ['/', '/search', '/video/:bvid', ...])
  GoRoute(path: path, builder: (context, state) => const SizedBox.shrink()),
```

真正的页面由工作区外壳（`lib/app/shell.dart` + `WorkspaceTabs` + 页面保留）自己挂载与切换，
切换不是 `Navigator.push`。`Hero` 的飞行发生在**同一 Navigator 的两条路由之间**，
在这种外壳里不会触发；同理 `CustomTransitionPage` 也不会生效。

因此本方案改为 **Overlay 过渡层**：目标页面照常先挂载（视频已经在播），过渡层盖在上面
把封面从起点矩形推到终点矩形，结束即移除。外壳的页面保留、返回历史、多标签语义完全不动。

## 2. 组件与文件

| 角色 | 位置 | 说明 |
| --- | --- | --- |
| 过渡实现 | `lib/shared/ui/cover_flight.dart` | `CoverFlight.run/reverse`、`CoverFlightReveal`、`captureFlightRect` |
| 起点几何 | 封面组件 `lib/shared/ui/video_card_cover.dart` | 点击回调里用 `captureFlightRect(context, cornerRadius: widget.borderRadius)` |
| 目标几何 | `lib/features/video/presentation/video_screen.dart` | 播放画面的全局矩形（全屏时即 `Offset.zero & size`） |
| 开播 | `PlaybackSession` / `PlaybackManager` | 目标页 `initState` 里立即 `prepare(play: true)` |
| 首帧预热 | `lib/features/video/application/video_card_preview_playback.dart` | 悬停预览播放器，转场前就已在出画 |

## 3.1 已接入（2026-11-02）

| 位置 | 改动 |
| --- | --- |
| `lib/shared/ui/cover_transition.dart`（新增） | 登记起点：`capture(context, cover:)`；播放：`playForward` / `playBack`；有效期 2 秒 |
| `lib/shared/ui/video_card.dart` | 封面外层加 `GlobalKey`，`onTap` 里先 `CoverTransition.capture(...)` 再导航 |
| `lib/app/shell.dart` → `_selectTab` | 切页后按 post-frame 播前进；若离开播放页则反向收起 |
| `lib/app/shell.dart` → `_closeCurrentTabOrBackWithinPage` | 关闭播放页后反跑同一组参数 |

判据：`flutter analyze` 对上述 4 个文件 **0 issues**；`verify/analysis-env` 单测 **11 项全过**
（含转场登记语义：无登记不播、clear 后失效）。

**未验证**：动画本体只在纯函数层面被断言（几何单调/非线性/端点精确），
真实观感（无跳变、反向落点、fps）必须在设备上确认；本条不构成“转场已验证”的结论。

## 3. 接入方式（三步）

1. 封面点击处：先 `captureFlightRect` 采样，再 `context.go` 到视频地址，
   紧接着 `CoverFlight.run(from: captured, to: 目标矩形, child: 封面图)`；
2. 目标页首帧就绪时调用 `CoverFlightReveal.markReady()`，过渡层在最后 40% 行程把封面淡出；
3. 返回时（外壳的 back 处理里）调用 `flight.reverse(duration: CoverFlight.reverseDuration)`，
   收起结束再切回主页，保证落点就是采样到的封面矩形。

## 4. 参数

| 项 | 值 | 理由 |
| --- | --- | --- |
| 展开时长 | 420 ms | 封面到全屏跨度大，300 ms 显得“抢” |
| 收起时长 | 320 ms | 离开比进入干脆 |
| 展开曲线 | `Curves.easeOutQuint` | 前段快、末段收 |
| 收起曲线 | `Curves.easeInCubic` | 与展开对称 |
| 几何二次缓动 | `fastOutSlowIn` | 非匀速拉伸，单测已断言非线性 |
| 圆角 | 6 → 0（`BorderRadius.lerp`） | 避免展开中途出现方角封面 |

## 5. 预加载与首帧

目标：**动画第一帧视频就在播**，而不是等转场结束。

1. **点击前预热**：封面悬停时已有的预览播放器（`video_card_preview_playback.dart`）
   会在悬停/静止后预打开媒体；转场时直接复用，首帧通常已在内存里。移动端没有悬停，
   改为「列表可见项预取播放地址 + 首帧」的轻量预热（只取 playurl，不建播放器）。
2. **点击后并行**：目标页 `initState` 立即 `prepare(play: true)`，不等过渡结束。
3. **封面兜底**：首帧未就绪时 `CoverFlightReveal.isReady == false`，过渡层封面全程不透明；
   就绪后才在末段淡出。因此慢网下也是「封面推到全屏 → 视频接管」，不会露黑底。

## 6. 鸿蒙（HarmonyOS）侧优化

| 优化 | 做法 | 目的 |
| --- | --- | --- |
| 尊重系统动效开关 | `MediaQuery.disableAnimationsOf(context)` 命中时 `duration` 设为零 | 鸿蒙「减弱动效」开启时不做位移，避免眩晕 |
| 过渡层独立图层 | 过渡载体包 `RepaintBoundary` | 转场期间不触发整屏重绘 |
| 禁用实时模糊 | 转场中不用 `BackdropFilter` 一类实时模糊 | 鸿蒙上实时模糊是性能重项（ArkUI 文档反复提示） |
| 圆角裁剪用 `ClipRRect` | 不用 `ClipPath` + 自定义 path | GPU 路径更短 |
| 图片解码尺寸 | 封面 `Image` 带 `cacheWidth`，预热时按目标宽高解码 | 全屏展开时避免二次解码抖动 |
| 系统栏过渡 | 展开期间保持 `setImmersiveModeEnabledState(true)` 不变 | 避免转场中状态栏跳变 |

ArkUI 原生壳一侧不需要为这个转场加代码：Flutter 内容区整体在 ArkUI 的 `FlutterPage` 里，
转场发生在 Flutter 内部。壳只负责窗口沉浸与避让区（见 `docs/harmony-adaptation.md`）。

## 7. 边界行为

| 场景 | 行为 |
| --- | --- |
| 视频加载慢 | 转场照常 420ms 完成，封面保留到首帧 |
| 加载失败 | 转场照常完成，落地显示错误态，封面作 poster |
| 动画中途返回 | `reverse()` 从当前位置反向，不跳回终点 |
| 快速连点 | 点击后 300ms 内忽略第二次点击 |
| 封面被裁到屏幕外 | `captureFlightRect` 与屏幕求交，只取可见部分 |
| 圆角不一致 | 由各卡片自己的 `borderRadius` 传入，插值到目标圆角 |

## 8. 自测与判据（已可执行）

`verify/analysis-env/test/cover_flight_test.dart`：

```
00:00 +5: All tests passed!
```

- 端点精确命中（`t=0` 与 `t=1` 分别等于起点/终点矩形，0 误差）
- 几何单调推进（40 段采样无回弹、无跳变）
- 非线性（t=0.25 处的宽度偏离线性插值 > 1px）
- 首帧未就绪时封面全程不透明；就绪后只在最后 40% 淡出

接入后还需人工验收：点击瞬间与点击前一帧做像素 diff（应无位移/缩放差）、
收起落点误差 ≤ 1px、转场期间 60fps、开启「减弱动效」时瞬时切换。