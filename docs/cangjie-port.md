# 仓颉移植手册

## 1. 为什么只移植纯计算

依据 [仓颉调研记录](research/cangjie-notes.md)（GitCode `Cangjie/cangjie_docs` 原文）：

| 约束 | 结论 |
| --- | --- |
| 跨语言唯一可验证边界 | C ABI（`@C` 导出 + 动态库 + Dart FFI），与仓库已有的 `bili_mux` 同形态 |
| `std`（1.2.0）缺 JSON/HTTP/哈希 | 它们在 `stdx`；鸿蒙 6.0+ 用 `stdx.crypto` 还必须自带 OpenSSL `.so` |
| 线程模型 | 仓颉线程可被调度到任意 OS 线程，阻塞式网络会占住 Dart isolate 调用栈 |

所以移植范围收窄为 **无网络、无 UI、无会话状态**的部分；网络/账号/队列仍由 Dart 的 `bili_api` 负责
（AGENTS.md 的既有边界不变）。

## 2. 模块

```
cangjie/
  cjpm.toml              cjc-version 1.2.0 / output-type dynamic / 目标 aarch64-linux-ohos
  src/ad/segment.cj      片段合并、来源优先级、置信度、segmentAt
  src/ad/airstrike.cj    边界聚类、片段生成
  src/abi/exports.cj     @C 导出：bilicore_version / bilicore_detect_airstrike
```

**分工**：弹幕文本的**时间码解析留在 Dart**（`AirstrikeDetector`），跨语言只传 `Int64`。
字符串/编码是最不适合做 FFI 边界的类型，两套运行时在编码与生命周期上互相假设容易出错。

## 3. C ABI 约定

- 所有时间单位是毫秒（`Int64`）。
- 置信度以千分比（`Int64`）跨边界，避免浮点。
- 输出缓冲由调用方分配，步长 3：`startMs, endMs, confidencePermille`。
- 返回写入条数；**容量不足返回负数**，其绝对值为所需条数，调用方据此重试。

## 4. 构建

```powershell
# 官方下载页 cangjie-lang.cn/download/1.2.0 → cangjie-sdk-windows-x64-ohos-1.2.0.zip
$env:CANGJIE_HOME = 'C:\cangjie\ohos'
& "$env:CANGJIE_HOME\envsetup.ps1"
cd cangjie
cjpm build --target aarch64-linux-ohos
```

产物 `target/aarch64-linux-ohos/release/libbilicore.so`，放进
`harmony/entry/src/main/libs/arm64-v8a/`；Dart 侧用 `DynamicLibrary.open('libbilicore.so')` 加载，
加载失败时回落到 Dart 实现（回落分支必须与仓颉实现语义一致，两者共用同一批 fixture）。

## 5. 本机验证状态

**未编译**。本机没有安装仓颉 SDK（官网下载按钮由 JS 触发，`window.__INITIAL_STATE__` 里没有文件 url，
Node fetch 取不到直链）。因此 `.cj` 文件只经过语法级审查，没有编译器背书。
装上 SDK 后第一件事是 `cjpm build --target aarch64-linux-ohos`，再用同一批 fixture 比对
Dart 与仓颉的片段输出是否逐条一致。
