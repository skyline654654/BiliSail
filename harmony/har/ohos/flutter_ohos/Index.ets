/**
 * OFFLINE STUB of the OpenHarmony Flutter embedding.
 *
 * The real package (openharmony-sig/flutter_flutter, har/ohos/flutter_ohos) exposes
 * FlutterPage/FlutterView and the MethodChannel plumbing. This stub only declares the
 * component signature so the ArkTS shell type-checks and links without the engine,
 * which is what lets `hvigorw assembleHap` run on a machine without DevEco.
 *
 * Build a real app: replace this directory with the engine har of the same name.
 */
@Component
export struct FlutterPage {
  build() {
    Column() {
      Text('Flutter engine har missing')
        .fontSize(12)
        .fontColor($r('sys.color.font_secondary'))
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
