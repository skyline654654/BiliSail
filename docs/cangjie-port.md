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

## 5. 本机验证状态（已编译）

2026-11-02 在本机完成首次真实编译：

```
Cangjie Compiler: 1.2.0 (cjnative)
Target: x86_64-w64-mingw32
Cangjie Project Manager: 1.2.0
cjpm build success
target/release/bilicore@bilisail/libbilicore@bilisail.dll
```

SDK 来源与校验：`cangjie-sdk-windows-x64-1.2.0.zip`，SHA-256
`7bd5088ad56fb03c1214e73ea076de5ac08580cc419a8cbd46a524ee1ca250bf` 与官网公布值一致。

### 编译期纠正的三处（初稿都是错的）

| 项目 | 初稿 | 编译器要求 |
| --- | --- | --- |
| 包名 | `package bilicore.ad` | `package bilisail::bilicore.ad`（`<organization>::<name>` + 相对 src 的目录路径） |
| 追加元素 | `ArrayList.append(x)` | `ArrayList.add(x)` |
| 排序 | `sort(comparator: …)` | `sortBy(comparator: …)`；两者均已 deprecated，推荐 `std.sort.sort(data, by!)` |

另外：`src/` 根目录必须有至少一个 `.cj`，否则 cjpm 报
「there is no .cj file in directory src」并静默跳过整个模块（本次踩过）。
`cjpm.toml` 不接受 `src-dir` 字段，源码目录固定为 `src`。

### 仍未验证

- `--target aarch64-linux-ohos` 交叉编译（本机已下载 `cangjie-sdk-windows-x64-ohos-1.2.0.zip`，待执行）。
- 真机/模拟器加载 `libbilicore.so`：需要鸿蒙设备与 DevEco。
- Dart 与仓颉两个实现的 fixture 交叉比对：两边都写好了，尚未跑同一批数据。

### 交叉编译到鸿蒙的实测结果（2026-11-02）

`cjpm build --target aarch64-linux-ohos` 用 `cangjie-sdk-windows-x64-ohos-1.2.0` 执行，**编译通过、链接失败**：

```
ld.lld: error: cannot open crti.o: No such file or directory
ld.lld: error: unable to find library -lm
ld.lld: error: unable to find library -lc
ld.lld: error: cannot open crtn.o: No such file or directory
```

原因：仓颉的 OHOS 交叉 SDK 只带仓颉运行时（`runtime/lib/linux_ohos_aarch64_cjnative`），
**不带 HarmonyOS 的 musl libc 与 crt 目标文件**——这些属于华为 HarmonyOS Native SDK（DevEco 的一部分）。
本机没有 DevEco，因此该 SDK 也无法补齐。要在本机完成 OHOS 链接，需要额外安装 HarmonyOS SDK
并把 `--target-sysroot` 指向其 native sysroot；否则只能在 DevEco 工程里由 hvigor 驱动交叉编译。

这条结论对项目的影响：`cangjie/` 的**源码正确性已被本机 windows 目标编译证实**，
但"产出 `libbilicore.so` 放进鸿蒙工程"这一步必须在装有 DevEco 的机器上完成。

### Dart ↔ 仓颉 语义等价比对（2026-11-02 实测）

`verify/compare.mjs` 把同一批 8 个 fixture 分别喂给两套实现，输出逐行比对：

| case | 输出 |
| --- | --- |
| typical_short_ad | `0-180000@670` |
| below_vote_threshold | （空） |
| clustered_votes | `0-420000@790` |
| too_short_segment | （空） |
| merged_close_boundaries | `0-200000@683` |
| beyond_duration | （空） |
| two_ads | `0-300000@750` |
| empty | （空） |

结果：**8/8 完全一致（IDENTICAL）**。这意味着仓颉实现不是"另写了一份相似逻辑"，
而是与线上 Dart 实现行为等价；将来任一侧改动都应重跑这个脚本。
