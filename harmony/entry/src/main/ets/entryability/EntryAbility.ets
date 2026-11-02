import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AvoidAreaWatcher } from '../harmony/AvoidAreaWatcher';
import { HarmonySystem } from '../harmony/HarmonySystem';

const DOMAIN: number = 0x0B11;
const TAG: string = 'EntryAbility';

/**
 * BiliSail 的鸿蒙入口。
 *
 * 职责边界：
 * 1. 窗口级沉浸：setImmersiveModeEnabledState(true)（API 12+，同步无返回值），
 *    与 setWindowLayoutFullScreen 共享同一状态。
 * 2. 避让区：交给 AvoidAreaWatcher，它按 TYPE_SYSTEM + TYPE_NAVIGATION_INDICATOR
 *    取最大值（px→vp），并订阅 avoidAreaChange。
 * 3. 内容：ArkUI 页面承载 Flutter 视图与**原生底栏**。
 *
 * 不用 setWindowSystemBarEnable([])：官方明确它只在窗口全屏/最大化时生效，
 * 自由窗口设备从 OpenHarmony 5.0.2 起「不生效也不报错」，无法用返回值判断。
 * 也不用 expandSafeArea 铺底栏：组件有固定宽高时它只支持 TOP/START，
 * 官方示例图注写明「未扩展至底部导航条」。
 */
export default class EntryAbility extends UIAbility {
  private avoidArea: AvoidAreaWatcher | undefined = undefined;

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    hilog.info(DOMAIN, TAG, 'onCreate');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    const mainWindow: window.Window = windowStage.getMainWindowSync();
    this.enableImmersiveWindow(mainWindow);

    this.avoidArea = new AvoidAreaWatcher(mainWindow);
    HarmonySystem.bind(mainWindow, this.avoidArea);

    windowStage.loadContent('pages/Index', (error) => {
      if (error.code !== 0) {
        hilog.error(DOMAIN, TAG, 'loadContent failed: %{public}s', JSON.stringify(error));
        return;
      }
      hilog.info(DOMAIN, TAG, 'content loaded');
    });
  }

  /**
   * 打开窗口级沉浸。
   *
   * setImmersiveModeEnabledState 是 API 12+ 的同步接口；老版本上它会抛错，
   * 此时回退到 API 9+ 的 setWindowLayoutFullScreen（返回 Promise）。
   */
  private enableImmersiveWindow(mainWindow: window.Window): void {
    try {
      mainWindow.setImmersiveModeEnabledState(true);
      hilog.info(DOMAIN, TAG, 'immersive window enabled (API 12+)');
      return;
    } catch (error) {
      const failure = error as BusinessError;
      hilog.warn(DOMAIN, TAG, 'setImmersiveModeEnabledState failed: %{public}s', failure.message);
    }
    mainWindow.setWindowLayoutFullScreen(true)
      .then(() => {
        hilog.info(DOMAIN, TAG, 'immersive window enabled (API 9 fallback)');
      })
      .catch((error: BusinessError) => {
        hilog.error(DOMAIN, TAG, 'setWindowLayoutFullScreen failed: %{public}s', error.message);
      });
  }

  onWindowStageDestroy(): void {
    this.avoidArea?.stop();
    this.avoidArea = undefined;
    HarmonySystem.unbind();
    hilog.info(DOMAIN, TAG, 'onWindowStageDestroy');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, TAG, 'onDestroy');
  }
}
