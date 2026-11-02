import { MethodChannel, MethodResult } from '@ohos/flutter_ohos';
import { HarmonySystem } from '../harmony/HarmonySystem';
import { AvoidAreaSides } from '../harmony/AvoidAreaWatcher';

/**
 * 把 Dart 侧的 `bilisail/harmony_system` 通道接到 HarmonySystem。
 *
 * Dart 侧约定（见 lib/core/platform/harmony_system.dart）：
 *   describe()             -> { apiVersion, hostsBottomBar, immersiveMaterial,
 *                              immersiveWindow, avoidAreaStream }
 *   queryAvoidArea()       -> { bottom, top, sources }
 *   applyImmersiveLayout() -> void
 * 还有一个 EventChannel `bilisail/harmony_system/avoid_area`，
 * 每次避让区变化推一次 { bottom, top, sources }。
 *
 * 这里刻意不实现旧版的 setNavigationIndicatorVisible：系统没有隐藏底部
 * 手势条的公开接口，保留它只会「假成功」。
 */
export class FlutterEngineGlue {
  private static channel: MethodChannel | undefined = undefined;

  /** 在 UIAbility 拿到 engine 之后调用一次。 */
  static attach(engine: object): void {
    FlutterEngineGlue.channel = new MethodChannel(engine, 'bilisail/harmony_system');
    FlutterEngineGlue.channel.setMethodCallHandler((call: MethodCall): MethodResult => {
      return FlutterEngineGlue.handle(call);
    });
  }

  static detach(): void {
    FlutterEngineGlue.channel?.setMethodCallHandler(null);
    FlutterEngineGlue.channel = undefined;
  }

  private static handle(call: MethodCall): MethodResult {
    switch (call.method) {
      case 'describe':
        return MethodResult.success(HarmonySystem.describe()) as MethodResult;
      case 'queryAvoidArea':
        return MethodResult.success(HarmonySystem.queryAvoidArea()) as MethodResult;
      case 'applyImmersiveLayout':
        HarmonySystem.applyImmersiveLayout();
        return MethodResult.success(null) as MethodResult;
      default:
        return MethodResult.notImplemented() as MethodResult;
    }
  }
}
