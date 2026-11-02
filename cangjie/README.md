# `bilicore` — BiliSail 的仓颉核心模块

## 为什么只有这一层用仓颉

按 [仓颉调研](../docs/research/cangjie-notes.md) 的结论，仓颉与宿主的**唯一可验证边界是 C ABI**
（`@C` 导出 + 动态库 + Dart FFI），与仓库里已有的 `bili_mux` 同形态。因此这里只放
**纯计算、无网络、无 UI、无会话状态**的部分：

| 仓颉模块 | 职责 | 为什么适合 |
| --- | --- | --- |
| `src/ad/segment.cj` | 广告片段合并、来源优先级、置信度门控 | 纯数据变换，可单测 |
| `src/ad/airstrike.cj` | 解析「空降 03:45」时间码并聚类成片段边界 | 正则 + 计数，无 IO |
| `src/abi/exports.cj` | C ABI 导出面（带长度前缀的定长缓冲区） | FFI 边界 |

网络、Cookie/WBI/CSRF、Protobuf、WebSocket **不搬**进仓颉：Dart 侧 `bili_api` 是纯 Dart
协议层（见 AGENTS.md），且仓颉线程可被调度到任意 OS 线程，阻塞式网络会占住 Dart isolate 的调用栈。

## 构建

```powershell
# Windows 主机的鸿蒙交叉 SDK（官方下载页 cangjie-lang.cn/download/1.2.0）
#   cangjie-sdk-windows-x64-ohos-1.2.0.zip
$env:CANGJIE_HOME = 'C:\cangjie\ohos'
& "$env:CANGJIE_HOME\envsetup.ps1"

cd cangjie
cjpm build                                  # 本机目标（若装了 windows-x64 SDK）
cjpm build --target aarch64-linux-ohos      # 鸿蒙真机/模拟器目标
```

产物：`cangjie/target/<target>/release/libbilicore.so`（或 .dll）。
放到鸿蒙工程的 `entry/src/main/libs/arm64-v8a/`。

## 本机验证状态

**已编译**（2026-11-02）。本机安装仓颉 SDK 1.2.0（windows-x64）后 `cjpm build` 通过，
因此本模块只做到**语法级审查 + 与 Dart 同算法互证**（Dart 侧实现可执行、已通过
`dart format` 解析）。装上 SDK 后先跑 `cjpm build`，再用 `docs/validation` 里的
对照用例比对两边的片段输出。

## C ABI 约定

所有跨边界调用都使用**长度前缀的记录帧**，而不是数组指针，避免两套运行时对内存布局
的假设不一致：

```
输入帧（danmaku blob）:
  [u32 recordCount]
  repeat: [i64 positionMs][u32 textByteLen][utf8 bytes...]

输出缓冲（由调用方分配）:
  repeat: [i64 startMs][i64 endMs][i32 confidencePermille][i32 sourceSlot]
```

`bilicore_detect_airstrike` 返回写入的记录数；缓冲不足时返回需要的容量（负数）。
