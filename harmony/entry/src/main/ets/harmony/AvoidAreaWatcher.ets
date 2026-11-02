import { window } from '@kit.ArkUI';
import { display } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0B11;
const TAG: string = 'AvoidAreaWatcher';

/**
 * 底部/顶部避让区，单位为 **vp**。
 *
 * 官方原文：getWindowAvoidArea 返回的 Rect「单位为 px」；这里统一换算成 vp
 * 再交给 Flutter，避免 Dart 侧再依赖设备密度。
 */
export interface AvoidAreaSides {
  bottom: number;
  top: number;
  /** 贡献了数值的避让类型，仅用于诊断：system / navigationIndicator */
  sources: string[];
}

/**
 * 监听窗口避让区的变化。
 *
 * 官方文档：'avoidAreaChange' 会在全屏/悬浮/分屏切换、旋转、折叠与跨设备
 * 流转时触发，所以底栏不能只信任启动时读到的值。
 *
 * 注意：TYPE_SYSTEM(0) 包含状态栏与三键导航栏；底部手势条属于
 * TYPE_NAVIGATION_INDICATOR(4, API 11+)；TYPE_SYSTEM_GESTURE(2) 官方原文为
 * 「当前所有设备均无此类型避让区域」，因此不订阅它。
 */
export class AvoidAreaWatcher {
  private mainWindow: window.Window;
  private density: number = 1;
  private callback?: (sides: AvoidAreaSides) => void;
  private registered: boolean = false;

  constructor(mainWindow: window.Window) {
    this.mainWindow = mainWindow;
    const info: display.Display = display.getDefaultDisplaySync();
    // densityPixels 即 1vp = densityPixels px
    this.density = info.densityPixels > 0 ? info.densityPixels : 1;
  }

  /** 记录 px 到 vp 的换算比例。 */
  private pxToVp(px: number): number {
    return px / this.density;
  }

  /** 读取一次当前避让区（单位 vp）。 */
  read(): AvoidAreaSides {
    let bottom: number = 0;
    let top: number = 0;
    const sources: string[] = [];
    try {
      const systemArea: window.AvoidArea =
        this.mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      top = Math.max(top, this.pxToVp(systemArea.topRect.height));
      bottom = Math.max(bottom, this.pxToVp(systemArea.bottomRect.height));
      sources.push('system');
    } catch (error) {
      const failure = error as BusinessError;
      hilog.warn(DOMAIN, TAG, 'TYPE_SYSTEM unavailable: %{public}s', failure.message);
    }
    try {
      // API 11+：底部手势条/导航指示条。低版本会抛错，忽略即可。
      const indicatorArea: window.AvoidArea =
        this.mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
      bottom = Math.max(bottom, this.pxToVp(indicatorArea.bottomRect.height));
      sources.push('navigationIndicator');
    } catch (error) {
      const failure = error as BusinessError;
      hilog.info(DOMAIN, TAG, 'TYPE_NAVIGATION_INDICATOR unavailable: %{public}s', failure.message);
    }
    const result: AvoidAreaSides = { bottom: bottom, top: top, sources: sources };
    return result;
  }

  /** 订阅变化并把最新值推给回调。重复调用是幂等的。 */
  start(callback: (sides: AvoidAreaSides) => void): void {
    this.callback = callback;
    if (this.registered) {
      return;
    }
    try {
      this.mainWindow.on('avoidAreaChange', (data: window.AvoidAreaOptions) => {
        // 事件只带一种类型的数据，重新整体读一次更稳妥。
        const handler = this.callback;
        if (handler !== undefined) {
          handler(this.read());
        }
        hilog.debug(DOMAIN, TAG, 'avoidAreaChange type=%{public}d', data.type);
      });
      this.registered = true;
    } catch (error) {
      const failure = error as BusinessError;
      hilog.warn(DOMAIN, TAG, 'subscribe failed: %{public}s', failure.message);
    }
  }

  /** 退订，供 UIAbility 销毁时调用。 */
  stop(): void {
    if (!this.registered) {
      return;
    }
    try {
      this.mainWindow.off('avoidAreaChange');
    } catch (error) {
      const failure = error as BusinessError;
      hilog.warn(DOMAIN, TAG, 'unsubscribe failed: %{public}s', failure.message);
    }
    this.registered = false;
    this.callback = undefined;
  }
}
