import { uiMaterial } from '@kit.ArkUI';

/** 底栏上的一个目的项。 */
export interface BottomBarItem {
  id: string;
  label: string;
  symbol: Resource;
  selectedSymbol: Resource;
}

/**
 * BiliSail 的鸿蒙原生底栏。
 *
 * 这是「所有组件能用系统级组件就尽量用」的落点：
 * - 用途项用 `SymbolGlyph`（系统符号）+ `Text`，跟 ArkUI 无障碍一起走；
 * - 材质用官方 `.backgroundBlurStyle(BlurStyle.COMPONENT_THICK)` 作为基线，
 *   在 API 26+ 上由 `uiMaterial.ImmersiveMaterial`（module.json5 的
 *   `ohos.arkui.UIMaterial.state=enable` 打开）接管，即官方「沉浸光感」；
 * - 底部预留高度来自 AvoidAreaWatcher，绝不用 expandSafeArea 硬铺——
 *   官方原文：组件有固定宽高时 expandSafeArea 只支持 TOP/START。
 */
@Component
export struct WorkspaceBottomBar {
  @Prop items: BottomBarItem[];
  @Prop selectedIndex: number;
  @Prop avoidBottom: number;
  onSelect: (index: number) => void = () => {};
  onCreate: () => void = () => {};

  @Builder
  private destinationSlot(item: BottomBarItem, index: number) {
    Column() {
      SymbolGlyph(index === this.selectedIndex ? item.selectedSymbol : item.symbol)
        .fontSize(22)
        .fontColor([index === this.selectedIndex ? $r('sys.color.font_primary') : $r('sys.color.font_secondary')])
      Text(item.label)
        .fontSize(10)
        .margin({ top: 2 })
        .fontColor(index === this.selectedIndex
          ? $r('sys.color.font_primary')
          : $r('sys.color.font_secondary'))
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .accessibilityText(item.label)
    .onClick(() => {
      this.onSelect(index);
    })
  }

  /** 中间「+」：与 B 站手机版一致，抬起的圆形主色按钮。 */
  @Builder
  private createSlot() {
    Column() {
      Stack() {
        Circle()
          .width(38)
          .height(38)
          .fill($r('sys.color.brand'))
        SymbolGlyph($r('sys.symbol.plus'))
          .fontSize(22)
          .fontColor([Color.White])
      }
      .width(48)
      .height(48)
      .align(Alignment.Center)
    }
    .width(64)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .accessibilityText('创作')
    .onClick(() => {
      this.onCreate();
    })
  }

  build() {
    Row() {
      ForEach(this.items, (item: BottomBarItem, index: number) => {
        // 中间位置插入「+」：与 Flutter 侧 WorkspaceBottomBar 的
        // items.length ~/ 2 保持一致。
        if (index === Math.floor(this.items.length / 2)) {
          this.createSlot()
        }
        this.destinationSlot(item, index)
      }, (item: BottomBarItem) => item.id)
    }
    .width('100%')
    .height(56 + this.avoidBottom)
    .padding({ bottom: this.avoidBottom })
    // 基线材质：所有 API 版本可用。
    .backgroundBlurStyle(BlurStyle.COMPONENT_THICK, {
      colorMode: ThemeColorMode.SYSTEM,
      adaptiveColor: AdaptiveColor.DEFAULT,
      scale: 1.0
    })
    // API 26+ 的系统材质会覆盖上面这层模糊；模块级开关见 module.json5。
    .systemMaterial(uiMaterial.MaterialType.IMMERSIVE)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  }
}
