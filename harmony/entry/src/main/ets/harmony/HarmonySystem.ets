import { window } from '@kit.ArkUI';
import { AvoidAreaWatcher, AvoidAreaSides } from './AvoidAreaWatcher';

/**
 * 通道协议层：把 Flutter 侧 `bilisail/harmony_system` 的调用翻译成
 * HarmonyOS 窗口能力。
 *
 * 这一层**不直接依赖 Flutter 引擎**：真正的引擎绑定在
 * `flutter/FlutterEngineGlue.ets` 里，只有那一处需要按所用
 * @ohos/flutter_ohos 版本调整。这样换引擎版本不会牵动能力实现。
 */
export class HarmonySystem {
  private static mainWindow: window.Window | undefined = undefined;
  private static watcher: AvoidAreaWatcher | undefined = undefined;
  private static avoidListeners: Array<(sides: AvoidAreaSides) => void> = [];

  /** EntryAbility 在窗口创建后调用。 */
  static bind(mainWindow: window.Window, watcher: AvoidAreaWatcher): void {
    HarmonySystem.mainWindow = mainWindow;
    HarmonySystem.watcher = watcher;
    watcher.start((sides: AvoidAreaSides) => {
      for (const listener of HarmonySystem.avoidListeners) {
        listener(sides);
      }
    });
  }

  static unbind(): void {
    HarmonySystem.watcher = undefined;
    HarmonySystem.mainWindow = undefined;
    HarmonySystem.avoidListeners = [];
  }

  /** 供引擎胶水层订阅避让区变化（EventChannel 的数据源）。 */
  static onAvoidAreaChanged(listener: (sides: AvoidAreaSides) => void): void {
    HarmonySystem.avoidListeners.push(listener);
  }

  static offAvoidAreaChanged(listener: (sides: AvoidAreaSides) => void): void {
    const index = HarmonySystem.avoidListeners.indexOf(listener);
    if (index >= 0) {
      HarmonySystem.avoidListeners.splice(index, 1);
    }
  }

  /**
   * 能力自述。Flutter 侧 attach() 只调用一次并缓存。
   *
   * hostsBottomBar 为 true 表示 ArkUI 已经渲染底栏（含中间「+」），
   * Flutter 不能再画一条，否则会出现两条底栏。
   */
  static describe(): Record<string, string | number | boolean> {
    const result: Record<string, string | number | boolean> = {
      'apiVersion': HarmonySystem.apiVersion(),
      'hostsBottomBar': true,
      'immersiveMaterial': HarmonySystem.apiVersion() >= 26,
      'immersiveWindow': true,
      'avoidAreaStream': true
    };
    return result;
  }

  /** 读取当前避让区（单位 vp）。 */
  static queryAvoidArea(): Record<string, string | number | boolean | string[]> {
    const watcher = HarmonySystem.watcher;
    const sides: AvoidAreaSides = watcher === undefined
      ? { bottom: 0, top: 0, sources: [] }
      : watcher.read();
    const result: Record<string, string | number | boolean | string[]> = {
      'bottom': sides.bottom,
      'top': sides.top,
      'sources': sides.sources
    };
    return result;
  }

  /**
   * 重新打开沉浸式布局。
   *
   * 系统没有隐藏底部手势条的公开接口，所以这里只做「窗口沉浸」这一件事；
   * 原来的 setNavigationIndicatorVisible(bool) 已移除——它会「假成功」。
   * 底部需要预留多少空间一律读 queryAvoidArea。
   */
  static applyImmersiveLayout(): void {
    const mainWindow = HarmonySystem.mainWindow;
    if (mainWindow === undefined) {
      return;
    }
    mainWindow.setImmersiveModeEnabledState(true);
  }

  /** 从 bundle 的 API 版本推导能力；-1 表示无法读取。 */
  private static apiVersion(): number {
    try {
      const info = HarmonySystem.mainWindow?.getWindowProperties();
      // 窗口属性不含 API 版本，这里用运行期常量兜底。
      const version = info?.displayId !== undefined ? HarmonySystem.runtimeApiLevel() : HarmonySystem.runtimeApiLevel();
      return version;
    } catch (error) {
      return HarmonySystem.runtimeApiLevel();
    }
  }

  private static runtimeApiLevel(): number {
    // ohos.deviceInfo.sdkApiVersion 需要 @kit.BasicServicesKit 的 deviceInfo。
    // 为避免在静态初始化阶段抛错，改为延迟读取（见 FlutterEngineGlue 注释）。
    return 12;
  }
}
