# 鸿蒙沉浸式底栏 / 沉浸光感 / 系统栏避让 API 调研

> 调研日期：2026-11-02
> 一手来源：Gitee 官方文档仓 [openharmony/docs](https://gitee.com/openharmony/docs)（`master`，本次读取提交 `b84779874332bd7c2afee0ca3875494fa4793f1f`，2026-04-27）。所有 raw 链接形如 `https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/...`。
> 补充来源：[华为开发者文档 UX 设计 - 沉浸光感](https://developer.huawei.com/consumer/cn/doc/doccenter-ux-design/immersivelight-0000002612101053)。该页由 JS 渲染，本机只能取到 1.9 KB 的空壳 HTML（正文与 JSON 接口均未取到），**因此本文不以该页正文为论据**，只在「沉浸光感」词条上标注其存在性。
> 标注约定：`<!--Del-->…<!--DelEnd-->` 内的文字在 OpenHarmony 文档渲染时被剔除、只在华为 HarmonyOS 文档中可见。本文引用时保留该语义并显式标注「Huawei-only」。

---

## 一、结论摘要（可直接照抄的 API 清单 + 最小示例）

### 1.1 能力 → API 对照表

| 需求 | API（所属对象） | 起始版本 | 备注 |
| --- | --- | --- | --- |
| 拿主窗口（同步） | `WindowStage.getMainWindowSync(): Window` | 9+ | 比 `getMainWindow()` 回调/Promise 更适合在组件里同步取窗口 |
| 开/关沉浸式布局 | `Window.setWindowLayoutFullScreen(isLayoutFullScreen: boolean): Promise<void>` | 9+（Promise 为重载主形态；Callback 重载自 12 起废弃） | 沉浸式=true 时布局**不避让**状态栏与三键导航栏 |
| 同上（同步、无返回值） | `Window.setImmersiveModeEnabledState(enabled: boolean): void` | 12+ | **这是 setWindowLayoutFullScreen 之外的第二个入口，不是它的替代**；两者共享同一状态，`getImmersiveModeEnabledState()` 可回读 |
| 查询是否沉浸 | `Window.getImmersiveModeEnabledState(): boolean` | 12+ | 未调用过上面两个接口时返回 false |
| 显示/隐藏状态栏与三键导航栏 | `Window.setWindowSystemBarEnable(names: Array<'status' \| 'navigation'>): Promise<void>` | 9+ | `[]` = 全隐藏；**仅在窗口全屏/最大化时生效** |
| 同上（按单条栏控制 + 动画） | `Window.setSpecificSystemBarEnabled(name: SpecificSystemBar, enable: boolean, enableAnimation?: boolean): Promise<void>` | 11+（`enableAnimation` 12+） | 子窗口无效 |
| 状态栏/导航栏颜色与文字色 | `Window.setWindowSystemBarProperties(props: SystemBarProperties): Promise<void>` | 9+ | 子窗口无效；全屏/最大化外不生效 |
| 状态栏文字色（18+ 新入口） | `Window.setStatusBarColor(color: ColorMetrics): Promise<void>` | 18+ | 只管文字色；`getStatusBarProperty()` 18+ 可回读 |
| 取避让区 | `Window.getWindowAvoidArea(type: AvoidAreaType): AvoidArea` | 9+ | 返回 **px**（整数），入库前需 `px2vp()` |
| 监听避让区变化 | `Window.on('avoidAreaChange', cb: Callback<AvoidAreaOptions>)` / `off` | 9+ | `AvoidAreaOptions = { type, area }` |
| 让「系统窗口/模态窗/悬浮窗」也能取避让区 | `Window.setSystemAvoidAreaEnabled(enabled: boolean): Promise<void>` | 18+ | 主窗不需要；`isSystemAvoidAreaEnabled()` 18+ 回读 |
| 隐藏窗口标题栏（2in1/平板窗口形态） | `Window.setWindowDecorVisible(isVisible: boolean): void` | 11+ | 必须在 `loadContent()/setUIContent()` 生效后调用；`getWindowDecorVisible()` 18+ |
| 组件绘制突破安全区 | `.expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])` | 10+ | 有严格触发条件，见 2.2 |
| 布局层忽略安全区 | `.ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.BOTTOM])` | 20+ | 与 expandSafeArea 同时设置时**先** ignoreLayoutSafeArea 再生效 |
| 容器级安全区内边距 | `.safeAreaPadding(padding: Padding \| LengthMetrics \| LocalizedPadding)` | 14+ | 参与 SAE 累加，可让子组件延伸 |
| 背景材质模糊（枚举） | `.backgroundBlurStyle(style: BlurStyle, options?: BackgroundBlurStyleOptions)` | 9+（18+/19+ 增加 Optional 与 SystemAdaptiveOptions 重载） | 封装「模糊半径+蒙版色+蒙版透明度+饱和度+亮度」 |
| 背景特效（自调参） | `.backgroundEffect(options: BackgroundEffectOptions)` | 11+（18+/19+ 重载） | radius / saturation / brightness / color / adaptiveColor |
| 背景模糊（只给半径） | `.backdropBlur(radius: number, options?: BlurOptions)` | 基础接口（无版本上标）；`options` 11+、`Optional<radius>` 18+ | 实时渲染，性能开销大；文档位于 background 属性页 |
| 内容模糊 | `.blur(value: number, options?: BlurOptions)` | 基础接口（无版本上标）；`options` 11+ | 模糊**自己的内容**，不是背景 |
| 状态栏区域智能反色 + 模糊 | `.systemBarEffect()` | 12+ | 原文仅一句「根据背景进行智能反色并且带有模糊效果」；未限定用途，适合叠在内容上的系统栏区域 |
| 系统材质（沉浸光感正解） | `.systemMaterial(material: uiMaterial.Material \| undefined)` | **26.0.0** | 配合 `new uiMaterial.ImmersiveMaterial({ style })` |
| 静态模糊（把图先糊掉再用） | `effectKit.createEffect(pixelMap).blur(radius)` | PixelMap 级 | 官方在性能章节反复推荐用它替代实时模糊 |
| 组件级 Filter 级联 | `uiEffect.createFilter().blur(px)` + `.backgroundFilter(filter)` | 12+ | 半径单位 **px** |
| 响应式断点（新） | `@Env(SystemProperties.BREAK_POINT) bp: uiObserver.WindowSizeLayoutBreakpointInfo` | 22+ | 取 `widthBreakpoint`/`heightBreakpoint`，响应式刷新 |
| 栅格断点（传统） | `GridRow({ breakpoints: { value: [...], reference: BreakpointsReference.WindowSize } })` | 9+ | 默认 `['320vp','600vp','840vp']` |

### 1.2 最小示例 A：Stage 模型里把窗口做成沉浸式，并拿到底部避让高度

```ts
// EntryAbility.ets
import { UIAbility } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';

export default class EntryAbility extends UIAbility {
  onWindowStageCreate(windowStage: window.WindowStage): void {
    const win = windowStage.getMainWindowSync();

    // 1) 沉浸式布局：布局不再避让状态栏/三键导航栏，组件可与其重叠
    win.setWindowLayoutFullScreen(true).catch((e: Error) => {
      console.error('layout full screen failed: ' + e.message);
    });

    // 2) 系统栏可见性：仅在窗口处于全屏/最大化时生效。
    //    ['status','navigation'] 全显示；[] 全隐藏；只留状态栏则 ['status']
    win.setWindowSystemBarEnable(['status']).catch((e: Error) => {
      console.error('system bar enable failed: ' + e.message);
    });

    // 3) 系统栏着色（子窗口无效）。透明背景 + 白字是最常见的沉浸式组合
    win.setWindowSystemBarProperties({
      statusBarColor: '#00000000',
      statusBarContentColor: '#FFFFFF',
      navigationBarColor: '#00000000',
      navigationBarContentColor: '#FFFFFF'
    }).catch((e: Error) => {
      console.error('system bar properties failed: ' + e.message);
    });

    // 4) 首次取避让区（px），底部 = 手势条/三键导航占据的高度
    const sys = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
    const indicator = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
    console.info(`bottom(status)=${sys.bottomRect.height}px indicator=${indicator.bottomRect.height}px`);

    // 5) 持续监听（旋转、分屏/悬浮切换、折叠屏、跨设备流转都会触发）
    win.on('avoidAreaChange', (data: window.AvoidAreaOptions) => {
      if (data.type === window.AvoidAreaType.TYPE_SYSTEM) {
        console.info('system avoid bottom(px)=' + data.area.bottomRect.height);
      } else if (data.type === window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR) {
        console.info('nav indicator bottom(px)=' + data.area.bottomRect.height);
      }
    });

    windowStage.loadContent('pages/Index');
  }

  onWindowStageDestroy(): void {
    // 监听在窗口销毁前解除，避免回调打到已释放对象
  }
}
```

要点：

- `setWindowLayoutFullScreen(true)` **只解决「不避让」**，系统栏是否显示由 `setWindowSystemBarEnable`/`setSpecificSystemBarEnabled` 决定，颜色由 `setWindowSystemBarProperties`/`setStatusBarColor` 决定。
- 从 API 10 起，沉浸式窗口默认已是「全屏大小 + 组件控制布局 + 状态栏/导航栏背景透明 + 文字黑色」，所以多数情况下**只需要** `setWindowLayoutFullScreen(true)` 再按需改文字色。
- `AvoidArea` 的 `leftRect/topRect/rightRect/bottomRect` 单位是 **px**（`Rect` 注释明确「单位为px，该参数为整数」），跨密度使用要 `px2vp()`。

### 1.3 最小示例 B：底部栏毛玻璃（三种写法按性能从低到高）

```ts
// 写法 1：BlurStyle 枚举 —— 最省事，官方封装的「材质」语义
Row() {
  // 底栏内容
}
.height(56)
.backgroundBlurStyle(BlurStyle.COMPONENT_THICK, {
  colorMode: ThemeColorMode.SYSTEM,   // 可固定 LIGHT / DARK
  adaptiveColor: AdaptiveColor.DEFAULT,
  scale: 1                            // 默认 1；小于 1 时模糊程度降低
})
.backgroundColor('#33FF0000')         // 半透明染色（也可用下方 linearGradient 代替）
.borderRadius(28)

// 写法 2：自己调参 —— 想要「通透 + 提亮」的玻璃感时
Row() {}
  .backgroundEffect({
    radius: 40,          // 模糊半径，[0, +∞)，默认 0
    saturation: 1.6,     // 饱和度，推荐 [0, 50]，默认 1
    brightness: 1.1,     // 亮度，推荐 [0, 2]，默认 1
    color: '#1FFFFFFF',  // 蒙版色，默认透明
    policy: BlurStyleActivePolicy.ALWAYS_ACTIVE,
    inactiveColor: '#FF1A1A1A' // 关模糊时用它兜底，避免掉成纯透明
  })

// 写法 3：只要一个半径 —— backdropBlur 实时模糊背景（性能最重）
Row() {}
  .backdropBlur(20, { grayscale: [0, 0] })
```

> 官方原话（同一段落出现在 backgroundEffect / backdropBlur / blur 三处）：「backgroundBlurStyle、blur 和 backdropBlur 为实时接口，每帧执行实时渲染，性能负载较大。当模糊内容与模糊半径均无需变动时，推荐采用静态模糊接口 blur。」

### 1.4 最小示例 C：沉浸光感（系统材质，HarmonyOS 6 / API 26）

```json5
// module.json5 —— 必须先声明开关，且只有 entry 类型 module 生效
{
  "module": {
    "type": "entry",
    "metadata": [
      { "name": "ohos.arkui.UIMaterial.state", "value": "enable" }
    ]
  }
}
```

```ts
import { uiMaterial } from '@kit.ArkUI';

@Entry
@Component
struct BottomBar {
  build() {
    Row() { /* 目的项 */ }
      .height(56)
      .borderRadius(28)
      // 沉浸式材质：由系统按算力分档渲染「材质层滤镜 + 阴影」
      .systemMaterial(new uiMaterial.ImmersiveMaterial({
        style: uiMaterial.ImmersiveStyle.REGULAR, // ULTRA_THIN / THIN / REGULAR / THICK / ULTRA_THICK
        colorInvert: false,                        // true 时，薄材质可按背景自动反色
        applyShadow: true                          // true 时材质自带阴影，优先于 .shadow()
      }))
  }
}
```

- 官方把「沉浸光感」直接影响写进了参数说明：`colorInvert` 的自动反色「与设置应用的沉浸光感的强弱配置相关。材质越薄、沉浸光感越强，越容易符合反色材质的要求」。
- `MaterialState`：`DEFAULT(0)` 只有 Dialog/Toast/AlphabetIndexer/文本菜单默认开启；`ENABLE(1)` 时 Chip/Select/Menu/Toggle/SegmentButton/bindSheet 等默认开启且**优先级高于组件自身背景色/模糊/阴影/边框**；`DISABLE(2)` 全部禁用。
- 单独关掉某个组件：`.systemMaterial(uiMaterial.Material.empty)`。
- 这是 **ArkUI 渲染管线内的能力**，Flutter 自绘的底栏拿不到（见第三节）。

### 1.5 最小示例 D：一次开发多端部署的断点判断

```ts
import { uiObserver, window } from '@kit.ArkUI';

@Entry
@Component
struct Adaptive {

  // API 22+：由框架在窗口尺寸变化时自动刷新（只读、不能初始化）
  @Env(SystemProperties.BREAK_POINT) bp: uiObserver.WindowSizeLayoutBreakpointInfo;
  @Env(SystemProperties.WINDOW_SIZE) sizeVp: window.SizeInVP;

  @Builder
  body() {
    if (this.bp.widthBreakpoint === WidthBreakpoint.WIDTH_SM) {
      // 手机竖屏：底部 Tabs
      PhoneLayout()
    } else if (this.bp.widthBreakpoint === WidthBreakpoint.WIDTH_MD) {
      // 折叠屏展开 / 小平板：底部 Tabs + 可选分栏
      TabletLayout()
    } else {
      // 平板横屏 / 2in1：Navigation 分栏 + 侧边 Tabs
      WideLayout()
    }
  }

  build() { Column() { this.body() }.width('100%').height('100%') }
}

// 传统写法（API 9+，无需 22）：GridRow 的断点直接驱动栅格
GridRow({
  columns: { xs: 2, sm: 4, md: 8, lg: 12, xl: 12, xxl: 12 },
  breakpoints: { value: ['320vp', '600vp', '840vp'], reference: BreakpointsReference.WindowSize },
  gutter: { x: 12, y: 12 }
}) {
  GridCol({ span: { xs: 2, sm: 2, md: 3, lg: 3 } }) { /* 视频卡 */ }
}
```

### 1.6 必须记住的 6 个坑

1. **`setWindowSystemBarEnable` 在非全屏/最大化模式下配置不生效**（悬浮窗、分屏场景），进全屏后才补生效——不要用它判断当前栏状态。
2. **自由窗口设备（2in1/平板自由窗口）从 OpenHarmony 5.0.2 起，`setWindowLayoutFullScreen` 与 `setImmersiveModeEnabledState` 在该状态下「不生效也不报错」**，切到非自由窗口态才生效。不要把它当失败。
3. **`expandSafeArea` 不是万能**：组件设了固定宽高（含 `'auto'`）时，只支持 `[SafeAreaEdge.TOP, SafeAreaEdge.START]` 扩展；且「组件的边界与安全区域重合时」才延伸到安全区下；父容器是滚动容器时自身不延伸。
4. **`avoidArea` 全是 px**，与 vp 混用会在不同 DPI 上错位。
5. **子窗口**（`createSubWindow`）默认就是沉浸式布局，但 `setWindowSystemBar* / setStatusBarColor` 对子窗无效。
6. **实时模糊逐帧渲染**：底栏常驻模糊请优先 `backgroundBlurStyle`/`backgroundEffect`，或改用静态 `effectKit.blur` 预糊图；不要给整页加 `backdropBlur`。

---

## 二、逐条来源与原文摘录

### 2.1 Stage 模型下的窗口与系统栏

来源：[zh-cn/application-dev/windowmanager/application-window-stage.md](https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/windowmanager/application-window-stage.md)

- 沉浸式能力定义（原文）：「窗口沉浸式能力：指对状态栏、导航栏等系统窗口进行控制，减少状态栏导航栏等系统界面的突兀感……沉浸式能力**只在应用主窗口作为全屏窗口时生效**。通常情况下，应用的辅助窗口（子窗、全局悬浮窗等）和处于自由窗口下的应用主窗口无法使用沉浸式能力。」
- 默认行为（原文）：「从 API version 10 开始，沉浸式窗口默认配置为全屏大小并由组件模块控制布局，状态栏、导航栏背景颜色为透明，文字颜色为黑色；应用窗口调用 `setWindowLayoutFullScreen` 接口，设置为 true 表示由组件模块控制忽略状态栏、导航栏的沉浸式全屏布局，设置为 false 表示由组件模块控制避让状态栏、导航栏的非沉浸式全屏布局。」
- 限制（原文）：「当前沉浸式界面开发仅支持窗口级别的配置，暂不支持 Page 级别的配置。若有 Page 级别切换的需要，可以在页面生命周期开始，例如 `onPageShow` 中设置沉浸模式，然后在页面退出，例如 `onPageHide` 中恢复默认设置来实现。」
- 两种实现方式（原文）：「方式一：应用主窗口为全屏窗口时，调用 `setWindowSystemBarEnable` 接口，设置导航栏、状态栏不显示……方式二：调用 `setWindowLayoutFullScreen` 接口，设置应用主窗口为全屏布局；然后调用 `setWindowSystemBarProperties` 接口，设置导航栏、状态栏的透明度、背景/文字颜色以及高亮图标等属性。」
- 子窗口：「子窗口创建后默认是[沉浸式布局]」。

### 2.2 ArkUI：expandSafeArea 的正确用法与触发条件

来源：[ts-universal-attributes-expand-safe-area.md](https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/reference/apis-arkui/arkui-ts/ts-universal-attributes-expand-safe-area.md)

签名（原文）：

```ts
expandSafeArea(types?: Array<SafeAreaType>, edges?: Array<SafeAreaEdge>): T
```

枚举（原文表）：

| 枚举 | 值 | 说明 |
| --- | --- | --- |
| `SafeAreaType.SYSTEM` | 0 | 系统默认非安全区域，包括状态栏、导航栏 |
| `SafeAreaType.CUTOUT` | 1 | 刘海/挖孔屏区域 |
| `SafeAreaType.KEYBOARD` | 2 | 软键盘区域 |
| `SafeAreaEdge.TOP / BOTTOM / START / END` | 0 / 1 / 2 / 3 | 上 / 下 / 前 / 尾 |

默认值（原文）：「types 默认值：`[SafeAreaType.SYSTEM, SafeAreaType.CUTOUT, SafeAreaType.KEYBOARD]`；edges 默认值：`[SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM, SafeAreaEdge.START, SafeAreaEdge.END]`」。

生效条件（原文，逐字）：

> - 设置 expandSafeArea 属性进行组件绘制扩展时，**建议组件尺寸不要设置固定宽高（百分比除外）**，当设置固定宽高（包括设置 `'auto'`）时，扩展安全区域的方向**只支持 [SafeAreaEdge.TOP, SafeAreaEdge.START]**，扩展后的组件尺寸保持不变。
> - 安全区域不会限制内部组件的布局和大小，不会裁剪内部组件。
> - 当父容器为滚动容器时，组件设置 expandSafeArea 属性后，自身不会延伸，但仍可触发其子节点中设置了 expandSafeArea 的延伸范围更新。
> - 设置 `expandSafeArea()` 时，不传参，走默认值处理；设置 `expandSafeArea([], [])` 时，相当于入参是空数组，此时 expandSafeArea 属性设置无效。
> - 组件设置 expandSafeArea 生效的条件为：① type 为 SafeAreaType.KEYBOARD 时默认生效，表现为组件不避让键盘；② 设置其他 type，**组件的边界与安全区域重合时**组件能够延伸到安全区域下。例如：设备顶部状态栏高度 100，那么组件在屏幕中的绝对位置需要为 0 <= y <= 100。
> - 组件延伸到避让区时，在避让区的事件如点击事件等可能会被系统拦截，优先给状态栏等系统组件响应。
> - 滚动类容器内的组件不建议设置 expandSafeArea 属性，如果设置，需要按照组件嵌套关系，将当前节点到滚动类祖先容器间所有直接节点设置 expandSafeArea 属性，否则 expandSafeArea 属性在滚动后可能会失效。
> - expandSafeArea 属性仅作用于当前组件，不会向父组件或子组件传递，因此使用过程中，所有相关组件均需配置。
> - 同时设置 expandSafeArea 和 position 属性时，position 属性会优先生效，expandSafeArea 属性会后生效。对于未设置 position、offset 等绘制属性的组件，如果其边界未与避让区重叠，设置 expandSafeArea 属性将不生效，如弹窗和半模态组件。
> - 对于 expandSafeArea 属性无法生效的场景，若要将组件部署在避让区，需要手动调整组件的坐标。

官方「沉浸式效果」示例（原文，把背景图铺到状态栏与手势条下）：

```ts
@Entry
@Component
struct SafeAreaExample1 {
  build() {
    Row() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundImage($r('app.media.bg'))
        .backgroundImageSize(ImageSize.Cover)
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }.height('100%')
  }
}
```

官方对「固定高度 + expandSafeArea」的实测说明（原文图注）：「Column 组件扩展至了顶部状态栏 [SafeAreaEdge.TOP]，**未扩展至底部导航条** [SafeAreaEdge.BOTTOM]，扩展后的组件高度维持设置值不变。」——这正是底栏想用 expandSafeArea 却失败的原因。

补充：挖孔区默认不算避让区，需要 module.json5 metadata 打开（原文）：「从 API version 12 开始，可在 module.json5 中添加以下配置项，摄像头挖孔区域会视为避让区」：

```json5
"metadata": [
  { "name": "avoid_cutout", "value": "true" }
]
```

相关但不用于绘制的布局级接口（同文件原文）：「ignoreLayoutSafeArea(types?: Array<LayoutSafeAreaType>, edges?: Array<LayoutSafeAreaEdge>): T」（20+，默认 `[LayoutSafeAreaType.SYSTEM]` / `[LayoutSafeAreaEdge.ALL]`）；「忽略布局安全区属性 ignoreLayoutSafeArea 和忽略渲染安全区属性 expandSafeArea 都设置时，`ignoreLayoutSafeArea` 先生效，`expandSafeArea` 在前者基础上再生效。」

### 2.3 窗口 API 的逐条签名（`@ohos.window`）

来源：[arkts-apis-window-Window.md](https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/reference/apis-arkui/arkts-apis-window-Window.md)、[arkts-apis-window-WindowStage.md](https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/reference/apis-arkui/arkts-apis-window-WindowStage.md)、[arkts-apis-window-i.md](https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/reference/apis-arkui/arkts-apis-window-i.md)、[arkts-apis-window-e.md](https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/reference/apis-arkui/arkts-apis-window-e.md)

**`getMainWindowSync`**（WindowStage.md，9+）：

```ts
getMainWindowSync(): Window
```

**`setWindowLayoutFullScreen`**（9+，Promise 为现行）：

```ts
setWindowLayoutFullScreen(isLayoutFullScreen: boolean): Promise<void>
```

原文：「设置应用主窗口或应用子窗口的布局是否为沉浸式布局……沉浸式布局生效时，布局不避让状态栏与三键导航栏，组件可能产生与其重叠的情况。非沉浸式布局生效时，布局避让状态栏与三键导航栏，组件不会与其重叠。」

设备行为差异（原文）：「从 OpenHarmony 5.0.2 开始，该接口在支持并处于自由窗口状态的设备上调用不生效也不报错，切换到非自由窗口状态时生效。」

**`setImmersiveModeEnabledState`**（12+，**API 18 之后仍无替代**）：

```ts
setImmersiveModeEnabledState(enabled: boolean): void
```

原文：「设置当前窗口是否开启沉浸式布局，该调用不会改变窗口模式和窗口大小。仅主窗口和子窗口可调用。」错误码 1300004：「Unauthorized operation. Invalid window type. Only main windows and subwindows are supported.」

`getImmersiveModeEnabledState(): boolean`（12+）原文：「返回值与 setImmersiveModeEnabledState() 以及 setWindowLayoutFullScreen() 设置结果一致，若未调用上述两个接口则默认返回 false。」

> **关于「API 18+ 是否有 setImmersiveModeEnabledState 的替代」**：查 `Window` 的 18+ 新增接口清单（`setSystemAvoidAreaEnabled`、`isSystemAvoidAreaEnabled`、`setStatusBarColor`、`getStatusBarProperty`、`on/off('keyboardDidShow'/'keyboardDidHide')`、`getWindowDecorVisible`、`snapshotIgnorePrivacy`、`isWindowHighlighted`、`setSubWindowZLevel`）**不存在沉浸开关的替代接口**；`setImmersiveModeEnabledState` 与 `setWindowLayoutFullScreen` 并存，是同步/异步两个入口。18+ 真正新增的沉浸配套是：系统窗口/模态窗也能取避让区（`setSystemAvoidAreaEnabled`）与状态栏文字色单点设置（`setStatusBarColor`）。

**`setWindowSystemBarEnable`**（9+）：

```ts
setWindowSystemBarEnable(names: Array<'status' | 'navigation'>): Promise<void>
```

原文：「设置主窗口状态栏、三键导航栏的可见模式……调用生效后返回并不表示状态栏、三键导航栏的显示或隐藏已完成。主窗口在非全屏/最大化模式（悬浮窗、分屏等场景）下配置不生效，进入全屏/最大化模式后配置生效。」

**`setSpecificSystemBarEnabled`**（11+）：

```ts
setSpecificSystemBarEnabled(name: SpecificSystemBar, enable: boolean, enableAnimation?: boolean): Promise<void>
```

原文：「子窗口调用后不生效。主窗口在非全屏/最大化模式……下配置不生效。」

**`setWindowSystemBarProperties`**（9+）+ `SystemBarProperties` 字段（i.md 原文表）：

```ts
setWindowSystemBarProperties(systemBarProperties: SystemBarProperties): Promise<void>

interface SystemBarProperties {
  statusBarColor?: string;                 // 十六进制 RGB/ARGB，返回时固定 ARGB
  isStatusBarLightIcon?: boolean;          // 7+
  statusBarContentColor?: string;          // 8+，设置后 isStatusBarLightIcon 无效，默认 '#E5FFFFFF'
  navigationBarColor?: string;
  isNavigationBarLightIcon?: boolean;      // 7+
  navigationBarContentColor?: string;      // 8+，默认 '#E5FFFFFF'
  enableStatusBarAnimation?: boolean;      // 12+
  enableNavigationBarAnimation?: boolean;  // 12+
}
```

**`setStatusBarColor`**（18+）：

```ts
setStatusBarColor(color: ColorMetrics): Promise<void>
```

原文：「设置主窗口状态栏的文字颜色……子窗口不支持设置状态栏文字颜色，调用无效果。」

**`getWindowAvoidArea`**（9+）：

```ts
getWindowAvoidArea(type: AvoidAreaType): AvoidArea
```

原文（场景与限制，逐字）：

> 主窗口/子窗口：
> - 自由窗口状态的自由悬浮窗口模式下，仅存在固定态软键盘（AvoidAreaType 为 TYPE_KEYBOARD）类型的避让区域。
> - 主窗口在非自由窗口状态的自由悬浮窗口模式下，仅存在系统栏（AvoidAreaType 为 TYPE_SYSTEM）类型的避让区域。
> - 主窗口在其余场景下，仅当在非自由悬浮窗口模式下或设备类型为 Phone 和 Tablet，才能通过此接口获取计算后的避让区域，否则获取的避让区域为空。
> - 子窗口在非自由窗口状态或非自由悬浮窗口模式下，仅当窗口的位置和大小与主窗口一致时，才能通过此接口获取计算后的避让区域，否则获取的避让区域为空。
>
> 全局悬浮窗、模态窗或系统窗口：仅在调用 setSystemAvoidAreaEnabled 方法使能后，才能通过此接口获取避让区域，否则获取的避让区域为空。
>
> 该接口一般适用于两种场景：在 onWindowStageCreate() 方法中，获取应用启动时的初始布局避让区域时可调用该接口；当应用内子窗需要临时显示，对显示内容做布局避让时可调用该接口。

**`on('avoidAreaChange')`**（9+）：

```ts
on(type: 'avoidAreaChange', callback: Callback<AvoidAreaOptions>): void
off(type: 'avoidAreaChange', callback?: Callback<AvoidAreaOptions>): void
```

原文（触发场景）：「常见的触发避让区回调的场景如下：应用窗口在全屏模式、悬浮模式、分屏模式之间的切换；应用窗口旋转；可折叠设备在屏幕折叠状态发生变化；应用窗口在多设备之间的流转。」

**`AvoidArea` / `AvoidAreaOptions` / `AvoidAreaType`**（i.md、e.md 原文）：

```ts
interface Rect { left: number; top: number; width: number; height: number; } // 单位 px，整数

interface AvoidArea {
  visible: boolean;   // 9+，「无实际意义，暂不支持使用」
  leftRect: Rect; topRect: Rect; rightRect: Rect; bottomRect: Rect;
}

interface AvoidAreaOptions {   // 12+
  type: AvoidAreaType;
  area: AvoidArea;
}
```

| `AvoidAreaType` | 值 | 原文说明 |
| --- | --- | --- |
| `TYPE_SYSTEM` | 0 | 系统默认区域。**包含状态栏和三键导航栏区域** |
| `TYPE_CUTOUT` | 1 | 挖孔区域 |
| `TYPE_SYSTEM_GESTURE` | 2 | 侧边返回手势区域。**当前所有设备均无此类型避让区域** |
| `TYPE_KEYBOARD` | 3 | 固定态软键盘区域 |
| `TYPE_NAVIGATION_INDICATOR` | 4 | 底部导航区域。当三键导航显示时，底部导航避让区域始终存在。*（原文含 Huawei-only 注：「OpenHarmony 各设备不支持此能力」）* |
| `TYPE_FLOAT_NAVIGATION` | 5 | 三键导航区域。*（Huawei-only 注：OpenHarmony 各设备不支持）*，起始版本 26.0.0 |

**`setSystemAvoidAreaEnabled`**（18+）：

```ts
setSystemAvoidAreaEnabled(enabled: boolean): Promise<void>
```

原文：「创建全局悬浮窗、模态窗或 WindowType 窗口类型为系统窗口时，调用该接口使能后才可以通过 getWindowAvoidArea() 获取窗口避让区信息或通过 on('avoidAreaChange') 监听窗口避让区变化。」默认值 false。

**`setWindowDecorVisible`**（11+）：

```ts
setWindowDecorVisible(isVisible: boolean): void
```

原文：「设置窗口标题栏是否可见，对存在标题栏和三键区的窗口形态生效。Stage 模型下，该接口需要在 loadContent() 或 setUIContent() 调用生效后使用。」「设置窗口标题栏不可见后，当主窗口进入全屏沉浸状态时，此时鼠标 Hover 到上方窗口标题栏热区上会显示悬浮标题栏。若想禁用悬浮标题栏显示，请使用 setTitleAndDockHoverShown() 接口。」

### 2.4 视觉：模糊、材质与「沉浸光感」

来源：[ts-universal-attributes-background.md](https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/reference/apis-arkui/arkui-ts/ts-universal-attributes-background.md)、[ts-universal-attributes-image-effect.md](https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/reference/apis-arkui/arkui-ts/ts-universal-attributes-image-effect.md)、[arkts-blur-effect.md](https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/ui/arkts-blur-effect.md)

**BlurStyle 枚举（原文全量）**：

| 名称 | 值 | 说明 |
| --- | --- | --- |
| `Thin` | - | 轻薄材质模糊 |
| `Regular` | - | 普通厚度材质模糊 |
| `Thick` | - | 厚材质模糊 |
| `BACKGROUND_THIN` | 3 | 近距景深模糊（10+） |
| `BACKGROUND_REGULAR` | 4 | 中距景深模糊（10+） |
| `BACKGROUND_THICK` | 5 | 远距景深模糊（10+） |
| `BACKGROUND_ULTRA_THICK` | 6 | 超远距景深模糊（10+） |
| `NONE` | 7 | 关闭模糊（10+） |
| `COMPONENT_ULTRA_THIN` | 8 | 组件超轻薄材质模糊（11+） |
| `COMPONENT_THIN` | 9 | 组件轻薄材质模糊（11+） |
| `COMPONENT_REGULAR` | 10 | 组件普通材质模糊（11+） |
| `COMPONENT_THICK` | 11 | 组件厚材质模糊（11+） |
| `COMPONENT_ULTRA_THICK` | 12 | 组件超厚材质模糊（11+） |

命名分两套：`BACKGROUND_*` 用于「透过组件看背景」，`COMPONENT_*` 用于「组件自身的材质」（含组件内容被材质化），底栏半透明玻璃通常用 `COMPONENT_*` 或 `BACKGROUND_*` 按设计取。

**`backgroundBlurStyle`**（9+/18+/19+）：

```ts
backgroundBlurStyle(value: BlurStyle, options?: BackgroundBlurStyleOptions): T                 // 9+
backgroundBlurStyle(style: Optional<BlurStyle>, options?: BackgroundBlurStyleOptions): T        // 18+
backgroundBlurStyle(style: Optional<BlurStyle>, options?: BackgroundBlurStyleOptions,
                    sysOptions?: SystemAdaptiveOptions): T                                      // 19+
```

原文：「为当前组件提供一种背景材质模糊能力，通过枚举值的方式封装了不同的模糊半径、蒙版颜色、蒙版透明度、饱和度、亮度。」options 不传时默认激活策略 `BlurStyleActivePolicy.ALWAYS_ACTIVE`；「当通过 backgroundBlurStyle 中的 inactiveColor 指定背景色时，不建议再通过 backgroundColor 设置背景色。」

`BackgroundBlurStyleOptions`（继承 `BlurStyleOptions`）+ `BlurStyleActivePolicy`（14+）：`policy` / `inactiveColor`。

**`backdropBlur`**（背景模糊）：

```ts
backdropBlur(value: number, options?: BlurOptions): T                       // 基础
backdropBlur(radius: Optional<number>, options?: BlurOptions): T            // 18+
backdropBlur(radius: Optional<number>, options?: BlurOptions,
             sysOptions?: SystemAdaptiveOptions): T                          // 19+
```

原文：「为组件添加背景模糊效果……入参为模糊半径，模糊半径越大越模糊，为 0 时不模糊。取值范围：[0, +∞)。」`BlurOptions.grayscale` 默认 `[0,0]`。

**`blur`**（内容模糊）：同形参；18+ 支持 undefined；19+ 支持 `SystemAdaptiveOptions`。

**`backgroundEffect` / `BackgroundEffectOptions`**（11+）：

```ts
backgroundEffect(options: BackgroundEffectOptions): T
backgroundEffect(options: Optional<BackgroundEffectOptions>): T                            // 18+
backgroundEffect(options: Optional<BackgroundEffectOptions>, sysOptions?: SystemAdaptiveOptions): T  // 19+

interface BackgroundEffectOptions {
  radius: number;              // 必填，[0, +∞)，默认 0
  saturation?: number;         // [0, +∞)，默认 1，推荐 [0, 50]
  brightness?: number;         // [0, +∞)，默认 1，推荐 [0, 2]
  color?: ResourceColor;       // 默认透明色
  adaptiveColor?: AdaptiveColor;  // DEFAULT / AVERAGE（AVERAGE 时 color 必须带透明度才生效）
  blurOptions?: BlurOptions;
  policy?: BlurStyleActivePolicy;   // 14+
  inactiveColor?: ResourceColor;    // 14+
}
```

**`systemBarEffect`**（12+，image-effect.md 原文一句话）：「根据背景进行智能反色并且带有模糊效果。」——状态栏/系统栏区域叠在视频或图片上时的官方解法。

**`uiEffect`（`@ohos.graphics.uiEffect`，12+）** 来源：[js-apis-uiEffect.md](https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/reference/apis-arkgraphics2d/js-apis-uiEffect.md)

```ts
import { uiEffect } from '@kit.ArkGraphics2D';
let filter: uiEffect.Filter = uiEffect.createFilter();
filter.blur(10);                    // 半径单位 px
// 用法：.backgroundFilter(filter)  —— 与 .blur() 不同，它是挂在 Filter 上的效果结点
```

原文：「blur(blurRadius: number): Filter —— 将模糊效果添加至组件上……模糊半径，单位为 **px**。」同模块另有 `VisualEffect` 与 `Filter.hdrBrightnessRatio(ratio)`（24+，需 `ohos.permission.HDR_BRIGHTNESS`），可做亮部提亮——与「光感」的高光观感相关，但属于 HDR 渲染管线。

**静态模糊（性能首选）** 来源：[js-apis-effectKit.md](https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/reference/apis-arkgraphics2d/js-apis-effectKit.md)

```ts
import { effectKit } from '@kit.ArkGraphics2D';
const headFilter = effectKit.createEffect(pixelMap);
headFilter.blur(radius);                 // px；「该接口为静态模糊接口……如果要对组件进行实时渲染的模糊，可以使用动态模糊」
```

**系统材质 / 沉浸光感（API 26）** 来源：[arkts-apis-uimaterial.md](https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/reference/apis-arkui/arkts-apis-uimaterial.md)、[ts-universal-attributes-image-effect.md](https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/reference/apis-arkui/arkui-ts/ts-universal-attributes-image-effect.md)

```ts
import { uiMaterial } from '@kit.ArkUI';

// 属性（image-effect.md）
systemMaterial(material: SystemUiMaterial | undefined): T   // 26.0.0

// 类型
type SystemUiMaterial = uiMaterial.Material;

// 类与枚举（uimaterial.md）
class ImmersiveMaterial extends Material { constructor(options?: ImmersiveOptions) }
enum ImmersiveStyle { ULTRA_THIN = 0, THIN = 1, REGULAR = 2, THICK = 3, ULTRA_THICK = 4 }
interface ImmersiveOptions { style?: ImmersiveStyle; materialColor?: ResourceColor; colorInvert?: boolean; applyShadow?: boolean }
enum MaterialState { DEFAULT = 0, ENABLE = 1, DISABLE = 2 }
enum MaterialType { IMMERSIVE = 2 }
interface MaterialInfo { state: MaterialState; type: MaterialType }
getMaterialInfo(): MaterialInfo
static get empty(): Material
```

原文（关键段落，逐字）：

> - 「沉浸式材质根据设备算力有分档表现，设备算力的高、中、低档由设备厂商决定，定义在系统配置文件中。在高档和中档算力设备上，影响材质层滤镜效果和阴影效果。在低档算力设备上，影响背景色、边框颜色、边框宽度、阴影效果。且同一材质的效果，会受到设置应用中**沉浸光感**配置项的影响，不同强弱程度的沉浸光感配置下，材质的参数和效果存在差异。」
> - `colorInvert`：「设置了材质对象的节点的子树是否自动适配材质到背景色的反色……只有材质参数足够薄时才会自动反色……**材质越薄、沉浸光感越强**，越容易符合反色材质的要求。」
> - `materialColor`：「该颜色需要带一定的透明度值，不能为纯不透明的颜色，否则会将材质滤镜效果完全遮挡。」
> - `applyShadow`：「当该参数为 true 时，材质中的阴影效果固定生效，优先于 shadow 通用属性。」

「沉浸光感」是系统级设计特性，官方 ArkUI 文档只在上述材质描述中出现该词；其独立设计规范页 [doccenter-ux-design/immersivelight](https://developer.huawei.com/consumer/cn/doc/doccenter-ux-design/immersivelight-0000002612101053) 由 JS 渲染，本机取不到正文（见文首说明），**不作引用**。

### 2.5 一次开发多端部署：断点 / GridRow / Navigation / Tabs

**栅格断点（原文表）** 来源：[arkts-layout-development-grid-layout.md](https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/ui/arkts-layout-development-grid-layout.md)

| 断点名称 | 取值范围（vp） | 设备描述 |
| --- | --- | --- |
| xs | [0, 320) | 最小宽度类型设备 |
| sm | [320, 600) | 小宽度类型设备（典型手机） |
| md | [600, 840) | 中等宽度类型设备（折叠屏展开/小平板） |
| lg | [840, +∞) | 大宽度类型设备（平板/2in1） |

原文：「栅格容器以设备的水平宽度（像素单位，单位 vp）作为断点依据……在 GridRow 栅格组件中，允许开发者使用 BreakPoints 自定义修改断点的取值范围，最多支持 6 个断点，除了默认的 4 个断点外，还可以启用 xl 和 xxl 断点。」

「考虑到应用可能以非全屏窗口的形式显示，**以应用窗口宽度为参照物更为通用**。」

**GridRow 参数默认值（原文）** 来源：[ts-container-gridrow.md](https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/reference/apis-arkui/arkui-ts/ts-container-gridrow.md)

- `columns`：「API version 20 之前：默认值为 12；API version 20 及之后：默认值为 `{ xs: 2, sm: 4, md: 8, lg: 12, xl: 12, xxl: 12 }`」
- `breakpoints`：默认 `{ value: ["320vp", "600vp", "840vp"], reference: BreakpointsReference.WindowSize }`
- `gutter`：默认 0，单位 vp
- 断点数组语义：「假设传入的数组是 [n0, n1, n2, n3, n4]，则 xs=[0,n0)、sm=[n0,n1)、md=[n1,n2)、lg=[n2,n3)、xl=[n3,n4)、xxl=[n4, INF)」

**系统断点枚举（13+，两套口径）** 来源：[ts-appendix-enums.md](https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/reference/apis-arkui/arkui-ts/ts-appendix-enums.md)

| `WidthBreakpoint` | 值 | 范围 |
| --- | --- | --- |
| `WIDTH_XS` | 0 | < 320vp |
| `WIDTH_SM` | 1 | [320, 600) |
| `WIDTH_MD` | 2 | [600, 840) |
| `WIDTH_LG` | 3 | [840, 1440) |
| `WIDTH_XL` | 4 | ≥ 1440vp |

| `HeightBreakpoint` | 值 | 范围（按**高宽比**） |
| --- | --- | --- |
| `HEIGHT_SM` | 0 | < 0.8 |
| `HEIGHT_MD` | 1 | [0.8, 1.2) |
| `HEIGHT_LG` | 2 | ≥ 1.2 |

原文补充：「下表列出了典型设备默认宽度断点的阈值划分……个别设备可根据需求通过产品化配置调整断点阈值。」→ **不要硬编码 600/840 当作绝对真值**。

**@Env 响应式环境变量（22+）** 来源：[arkts-env-system-property.md（指南）](https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/ui/arkts-env-system-property.md)、[ts-env-system-property.md（API）](https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/reference/apis-arkui/arkui-ts/ts-env-system-property.md)

| SystemProperties | 值 | 可获取类型 | 起始 |
| --- | --- | --- | --- |
| `BREAK_POINT` | `'system.arkui.breakpoint'` | `uiObserver.WindowSizeLayoutBreakpointInfo` | 22+ |
| `WINDOW_SIZE` | `'system.window.size'` | `window.SizeInVP` | 23+ |
| `WINDOW_SIZE_PX` | `'system.window.size.px'` | `window.Size` | 23+ |
| `WINDOW_AVOID_AREA` | `'system.window.avoidarea'` | `window.UIEnvWindowAvoidAreaInfoVP` | 23+ |
| `WINDOW_AVOID_AREA_PX` | `'system.window.avoidarea.px'` | `window.UIEnvWindowAvoidAreaInfoPX` | 23+ |

原文限制：「`@Env` 仅支持在 `@Component` 和 `@ComponentV2` 中使用」「`@Env` 装饰的变量为只读属性，不允许开发者进行初始化或赋值操作」「`@Env` 只能单独使用，不能和其他 V1/V2 状态变量装饰器或 `@Require` 联用」。响应式监听用 `UIUtils.addMonitor(this.breakpoint, ['widthBreakpoint','heightBreakpoint'], cb)`。

`WINDOW_AVOID_AREA` 的结构（i.md）正是沉浸式的四条边：

```ts
interface UIEnvWindowAvoidAreaInfoVP {   // 23+
  statusBar: UIEnvAvoidAreaVP;           // TYPE_SYSTEM
  cutout: UIEnvAvoidAreaVP;              // TYPE_CUTOUT
  keyboard: UIEnvAvoidAreaVP;            // TYPE_KEYBOARD
  navigationIndicator: UIEnvAvoidAreaVP; // TYPE_NAVIGATION_INDICATOR
}
```

**Navigation 分栏** 来源：[arkts-navigation-split-mode.md](https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/ui/arkts-navigation-split-mode.md)

原文：「Navigation 作为一个容器组件，提供了两种布局样式：单栏布局、分栏布局。分栏布局一般适用于宽屏设备，在分栏布局下，导航栏（navBar）会固定显示，子页面（NavDestination）通过导航控制器（NavPathStack）切换显示，在导航栏和子页面之间有一条分割线，可以通过分割线拖拽控制左右显示的比例。」

接口（原文列表）：`mode`（`NavigationMode.Stack / Split / Auto`）、`navBarPosition`（Start/End，受 RTL 影响）、`enableDragBar`（14+）、`navBarWidth`、`navBarWidthRange`（10+）、`minContentWidth`（10+）、`hideNavBar`、`enableModeChangeAnimation`（15+）、`splitPlaceholder`（20+，「仅作为 UI 展示页，仅分栏模式空栈的情况下才展示，不受路由栈管理也不可获焦和响应事件」）。

**Tabs 的多端形态** 来源：[arkts-navigation-tabs.md](https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/ui/arkts-navigation-tabs.md)

- 底部导航：「导航栏位置使用 Tabs 的 barPosition 参数进行设置。默认情况下，导航栏位于顶部，此时 barPosition 为 BarPosition.Start。设置为底部导航时，需要将 barPosition 设置为 BarPosition.End。」配合 `TabContent().tabBar(BottomTabBarStyle...)`（9+）。
- 侧边导航：「实现侧边导航栏需要将 Tabs 的 vertical 属性设置为 true」「vertical 为 false 时，tabbar 的宽度默认为撑满屏幕的宽度，需要设置 barWidth 为合适值；vertical 为 true 时，tabbar 的高度默认为实际内容的高度，需要设置 barHeight 为合适值。」

→ 结论：phone 用 `barPosition: End`；平板横屏/2in1 用 `vertical(true)` 侧边栏或 `Navigation` 分栏，二者都建立在同一份断点判断上。

### 2.6 沉浸式下的安全区与底部手势条

- **底部手势条对应的避让类型**：`AvoidAreaType.TYPE_NAVIGATION_INDICATOR = 4`（11+），原文：「表示底部导航区域。当三键导航显示时，底部导航避让区域始终存在。」另有 `TYPE_SYSTEM`（含状态栏 + 三键导航栏）。两者都要读，取 `Math.max(bottomRect.height)` 作为底栏内边距。
- **纯手势导航设备的坑**：`TYPE_SYSTEM_GESTURE`（侧边返回手势）原文「当前所有设备均无此类型避让区域」，不要指望它返回宽度。
- **组件级避让**：`.safeAreaPadding()`（14+）原文：「允许容器向自身添加组件级安全区域，供子组件延伸……系统级避让区域（如状态栏、导航条、挖孔区等）可视为页面容器特有的 safeAreaPadding，同样参与该延伸范围的计算。」；配合 `.ignoreLayoutSafeArea()`（20+）让子组件布局延伸。
- **Web 内容**：来源 [web-safe-area-insets.md](https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/web/web-safe-area-insets.md)，「Web 组件提供利用 W3C CSS 进行安全区域计算和避让适配的能力」，网页侧需 `<meta name='viewport' content='viewport-fit=cover'>` 才能拿到 `env(safe-area-inset-*)`。
- **键盘避让**：`UIContext.setKeyboardAvoidMode()`（11+）原文：「`KeyboardAvoidMode.RESIZE` 模式会压缩页面大小……设置 KeyboardAvoidMode 的 RESIZE 模式时，`expandSafeArea([SafeAreaType.KEYBOARD],[SafeAreaEdge.BOTTOM])` 不生效。」

---

## 三、本项目可用性评估（BiliSail / `_bilisail/work/BiliSail-OpenHarmony`）

### 3.1 现状事实（读仓库确认，非推测）

- 主工程是 **Flutter/Dart**（`AGENTS.md` 与 `pubspec.yaml`），构建目标为 Android/Windows/macOS；仓库内**没有** `ohos/` 原生工程目录（`glob **/ohos/**` 为空），也没有 ArkTS 页面。
- 已有鸿蒙接入点是 **MethodChannel 桥**：[`lib/core/platform/harmony_system.dart`](../../lib/core/platform/harmony_system.dart) 声明 `bilisail/harmony_system` 通道，含 3 个方法：`applyImmersiveLayout`、`setNavigationIndicatorVisible`、`bottomAvoidHeight`（另有 `supportsImmersiveLight` / `supportsWindowImmersiveLayout` 两个能力位，均以 `Platform.operatingSystem == 'ohos'` 门控）。`MissingPluginException`/`PlatformException` 被吞掉，属于「装饰性能力缺失不报错」的设计。
- 视觉层已有 [`ImmersiveLightSurface`](../../lib/core/presentation/immersive_light_surface.dart)：`BackdropFilter(ImageFilter.blur(sigma=20))` + `opacity 0.72` + 顶部发丝高光 + 渐变；[`ImmersiveLightTheme`](../../lib/core/presentation/immersive_light_theme.dart) 只改 ThemeData 的 chrome 槽位（决策 D70）。
- 决策 D70 已明确边界：「玻璃层的真实背景（壁纸）由原生壳提供，Flutter 只负责 tint 与光晕；未接入原生壳时视觉近似但不等价。」

### 3.2 结论：哪些 API 能落进本项目，哪些不能

| API 类别 | 能否用于本项目 | 原因 / 落点 |
| --- | --- | --- |
| `window.*`（`getMainWindowSync`、`setWindowLayoutFullScreen`、`setImmersiveModeEnabledState`、`setWindowSystemBarEnable`、`setSpecificSystemBarEnabled`、`setWindowSystemBarProperties`、`setStatusBarColor`、`getWindowAvoidArea`、`on('avoidAreaChange')`、`setWindowDecorVisible`） | **能，但必须在 ArkTS 原生壳里实现**，Flutter 侧只经 MethodChannel 消费 | 这些是 `@ohos.window` 的 Ability 侧 API，Dart 无法直接调用；对应 `HarmonySystem` 的 3 个方法 |
| `expandSafeArea` / `ignoreLayoutSafeArea` / `safeAreaPadding` / `backgroundBlurStyle` / `backgroundEffect` / `backdropBlur` / `systemBarEffect` / `systemMaterial` | **不能直接用** | 全是 ArkUI 组件属性；Flutter 在 OHOS 上自绘整棵 UI 树，不经过 ArkUI 的组件属性管线 |
| `@Env(SystemProperties.BREAK_POINT/WINDOW_SIZE/WINDOW_AVOID_AREA)`、`GridRow`/`GridCol`、`Navigation` 分栏、`Tabs` barPosition/vertical | **不能直接用；但可作为设计基准** | Flutter 侧已有自己的响应式实现，需要把 vp→逻辑像素的断点阈值（600/840）对齐到 `WINDOW_SIZE` 上报的数据 |
| `uiMaterial.ImmersiveMaterial`（沉浸光感） | **当前架构下拿不到** | 系统材质只在 ArkUI 渲染管线内生效；Flutter 自绘底栏只能做「近似」（现有 `ImmersiveLightSurface`）。若将来上 ArkTS 页面，`systemMaterial` 是唯一正解 |

### 3.3 MethodChannel 契约建议（把上表映射成可实现的原生壳行为）

| Dart 方法 | 原生壳（ArkTS）实现要点 | 依据 |
| --- | --- | --- |
| `applyImmersiveLayout` | `win.setWindowLayoutFullScreen(true)`；再按设计决定 `setWindowSystemBarEnable(['status'])`（保留状态栏、隐藏三键导航）或 `setSpecificSystemBarEnabled('navigation', false, true)`；透明底 + 白色文字用 `setWindowSystemBarProperties({statusBarColor:'#00000000', navigationBarColor:'#00000000', statusBarContentColor:'#FFFFFF'})` | 2.1 / 2.3 |
| `setNavigationIndicatorVisible(visible)` | **系统没有「隐藏手势条」的公开接口**。可做的是：按 `getWindowAvoidArea(TYPE_NAVIGATION_INDICATOR)` 决定是否留出底部内边距；或改状态栏/导航栏透明度让指示条视觉上淡出。若真要控制指示条自身颜色，只能走 `setWindowSystemBarProperties` 的 `navigationBarContentColor`。**建议把该方法语义改为「查询并回报」而非「设置」**，否则会出现「调用成功但无效果」的假成功 | 2.3 / 2.6 |
| `bottomAvoidHeight` | 分别取 `TYPE_SYSTEM` 与 `TYPE_NAVIGATION_INDICATOR` 的 `bottomRect.height`（**px**），`px2vp()` 后取最大值返回；并订阅 `on('avoidAreaChange')` 在变化时回推 | 2.3 |

注意三点：

1. `getWindowAvoidArea` 在「自由悬浮窗口模式」下只返回键盘或只返回系统栏，**悬浮窗场景要按窗口模式降级**，不能把空避让区当作 0 高度直接贴底。
2. 自由窗口设备（2in1/平板自由窗口）从 5.0.2 起 `setWindowLayoutFullScreen` 在该状态不生效，**桌面上「沉浸式」会退化为普通窗口**——这与 Flutter 桌面端的现有行为一致，可接受，但要在文档里写清。
3. `setWindowSystemBarEnable` 只影响全屏/最大化态；若应用是悬浮窗，调用会被静默忽略。

### 3.4 与现有实现的差距（按投入产出排序）

1. **底部避让高度目前是 0**：`bottomAvoidHeight()` 在无原生壳时返回 0，底栏会压在手势条上。原生壳实现后可一次解决，且顺带修正 `SafeArea.bottom` 与 `MediaQuery.padding.bottom` 的偏差。
2. **模糊是 Flutter 自绘**：`BackdropFilter` 在 OHOS 的 Impeller/Skia 路径上每帧采样，与 ArkUI 的 `backgroundBlurStyle` 相比缺少「蒙版色 + 饱和度 + 亮度」的统一调参，视觉上偏「灰」。若要贴近系统观感，可用 `backgroundEffect` 的参数作为设计基准反推 Flutter 的 `ImageFilter`/叠色参数（radius 40 / saturation 1.6 / brightness 1.1 这一档）。
3. **沉浸光感无法原生复用**：`systemMaterial` 属 API 26 + ArkUI 渲染管线，Flutter 页面结构决定拿不到。**不要为此把页面改写成 ArkTS**；维持 D70 的「主题层近似 + 原生壳提供真实背景」策略，把「材质分档随算力变化」的差异记为不可达项。
4. **可选项**：`setStatusBarColor`（18+）比 `setWindowSystemBarProperties` 更精准地只改文字色，适合深色播放页里状态栏图标自动反色；`systemBarEffect()`（12+）在纯 ArkUI 页面上是「状态栏区域智能反色」最省事的写法，若将来有 ArkTS 播放页可直接用。

### 3.5 未验证 / 不能声称的部分

- 未在真机或模拟器上运行任何 ArkTS 代码；本文所有签名与行为均来自官方文档原文，**没有一条经过实机验证**。
- 未核实当前 Flutter 版本（3.47.6）对应的 OpenHarmony Flutter 引擎是否支持 `Platform.operatingSystem == 'ohos'` 与 MethodChannel（`harmony_system.dart` 的注释声称如此，属于既有代码假设，不是本次调研结论）。
- 华为侧「沉浸光感」设计规范页正文未能取得（JS 渲染 + 无可用 JSON 接口），因此**「什么样的界面元素应该用沉浸光感」这类设计判断没有官方依据**，本文只覆盖到 API 与语义层面。
- `TYPE_NAVIGATION_INDICATOR` 与 `TYPE_FLOAT_NAVIGATION` 在原始 md 中带 Huawei-only 注记（「OpenHarmony 各设备不支持此能力」）；纯 OpenHarmony 设备上的实际返回值需实测。
