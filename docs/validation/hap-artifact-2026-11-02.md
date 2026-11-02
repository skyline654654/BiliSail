# 签名 HAP 产物校验记录（2026-11-02）

本文件记录 `harmony/dist/bili-easy-signed.hap` 的实际内容与校验方式，**每一项都是命令输出**，不是推断。

## 1. 产物

| 项 | 值 |
| --- | --- |
| 文件 | `harmony/dist/bili-easy-signed.hap` |
| 大小 | 314,742 B |
| SHA-256 | `0656525b6382b86941d02bd59a5ad57cff04393696032614dabf22dca2ee2556` |
| 构建 | `hvigorw assembleHap --no-daemon` → BUILD SUCCESSFUL in 9s 644ms |
| 签名 | `hap-sign-tool sign-app -mode localSign` → Sign Hap success |
| 校验 | `hap-sign-tool verify-app` → **Verify success** |

## 2. 包内清单（`unzip -l`）

```
    53988  ets/modules.abc          # ArkTS 编译产物
        8  .pages.info
    18039  ets/sourceMaps.map
     1538  module.json
      572  pack.info
      302  pkgContextInfo.json
      608  resources.index
   199620  resources/base/media/app_icon.png
       23  resources/base/profile/main_pages.json
```

共 9 个文件、解压后 274,698 B。说明 ArkTS 确实被编译进了 `modules.abc`，不是空壳包。

## 3. `module.json` 关键字段（`unzip -p … module.json`）

| 字段 | 值 | 说明 |
| --- | --- | --- |
| `bundleName` | `dev.bilisail.client` | 与 AGC 应用、`AppScope/app.json5` 一致 |
| `label` | `$string:app_name` | 指向已改为 bili easy 的字符串资源 |
| `versionName` / `versionCode` | `1.2.6` / `1000260` | 与 `app.json5` 一致 |
| `targetAPIVersion` | `260000026` | 编译用的 API 26 |
| `compileSdkVersion` | `26.0.0.105` | HarmonyOS Command Line Tools 26.0.0.865 |
| `metadata` | `ohos.arkui.UIMaterial.state = enable` | **系统「沉浸光感」材质开关确实在包里** |
| `debug` / `buildMode` | `true` / `debug` | 当前是 debug 构建（侧载调试用） |
| `vendor` | `bilisail` | — |

## 4. 已知问题：release 模式构建失败

```
hvigorw assembleHap -p buildMode=release
  → ERROR: Failed :entry:default@CompileArkTS
  → 00304036 Not Found  (AdaptorError)
  → BUILD FAILED in 3s 346ms
```

debug 模式同一份代码 BUILD SUCCESSFUL，所以不是业务代码问题，而是 release 链路缺东西。
当前观察到的线索（尚未定位）：

1. `flutter_ohos` 是**手写的离线 HAR 桩**（真实引擎 har 缺失），hvigor 已警告
   「HAR modules cannot be installed independently / applyToProducts 不生效」；
2. release 编译会额外做产物裁剪与 API 检查，桩模块可能缺少 release 需要的声明或产物。

结论：**release HAP 目前产不出来**，已产出的签名包是 debug 构建。侧载到测试设备调试是可行的，
但不适合作为对外分发包。要出 release，先换真实 `@ohos/flutter_ohos` 引擎 har（见 `docs/harmony-adaptation.md` 第 8 节）。

## 5. 本轮按官方建议补的配置

`build-profile.json5` 的 product 里显式加了 `targetSdkVersion`（与 `compatibleSdkVersion` 同为 `5.0.0(12)`），
消除 hvigor 的告警：

> WARN: The project has not explicitly set the 'targetSdkVersion' version at build-profile.json5. It is recommended to configure it.
