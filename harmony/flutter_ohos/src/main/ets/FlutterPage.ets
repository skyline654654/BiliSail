/**
 * OFFLINE STUB of the OpenHarmony Flutter embedding component.
 *
 * The real har (openharmony-sig/flutter_flutter → har/ohos/flutter_ohos) exposes
 * FlutterPage/FlutterView plus the MethodChannel plumbing. This stub keeps the same
 * exported name and component signature so the ArkTS shell compiles and links on a
 * machine without the engine. Replace this module with the engine har to run on device.
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
