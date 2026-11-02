import { FlutterPage } from '@ohos/flutter_ohos';

/**
 * Flutter 视图在 ArkUI 里的宿主。
 *
 * 这是整个原生壳里**唯一**与 @ohos/flutter_ohos 版本强绑定的位置：
 * 不同版本的 har 导出的组件名可能是 `FlutterPage`（页面级）或
 * `FlutterView`（视图级）。接入选型时只需改这一处导入与标签。
 */
@Component
export struct BilisailFlutterSurface {
  build() {
    FlutterPage()
      .width('100%')
      .height('100%')
  }
}
