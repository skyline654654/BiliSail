# 适配层引用与许可说明

本文件记录**适配过程中查阅、参考或直接依赖**的外部项目，以及每个项目的许可状态。
只写核实过的结论；无法核实的明确标注「未核实」，不猜测。

核查时间：2026-11-02。方式：GitHub API 与 Gitee API 的 `license` 字段。

## 1. 上游项目（本仓库的派生来源）

| 项目 | 地址 | 许可 | 与本文的关系 |
| --- | --- | --- | --- |
| BiliSail（上游） | <https://github.com/CKopoer/BiliSail> | **仓库未声明 LICENSE**（API 返回 license: null） | 本仓库是其 fork，保留全部上游代码与作者信息；适配只新增/修改文件 |
| 上游作者 | CKopoer | — | 版权归上游作者，本适配不改变其署名 |

> 上游未声明许可证时默认「保留所有权利」。本 fork 因此不额外声明许可，仅按 GitHub fork 机制分发，
> 并把改动范围写在 docs/ 里供上游合入。

## 2. 官方文档（查阅依据，未复制代码）

| 来源 | 地址 | 许可 | 用途 |
| --- | --- | --- | --- |
| OpenHarmony 官方文档 | <https://gitee.com/openharmony/docs> | **CC-BY-4.0**（已验证） | ArkUI / window / avoidArea / uiMaterial 等 API 依据 |
| 华为开发者文档 | <https://developer.huawei.com/consumer/cn/doc/> | 华为开发者协议，未逐条核实 | 云调试、AGC 流程、DevEco 工具体系 |
| 仓颉官方文档 | <https://cangjie-lang.cn/docs> | **未核实**（GitCode API 400） | cjpm / @C 互操作 / 标准库边界 |

## 3. 协议与数据参考

| 项目 | 地址 | 许可 | 用途 |
| --- | --- | --- | --- |
| bilibili-API-collect | <https://github.com/SocialSisterYi/bilibili-API-collect> | **未声明 LICENSE**（API 返回 null；默认分支已改名为 deprecated） | 仅用于比对投稿端点；实际结论以对真实账号的只读探测为准 |
| BilibiliSponsorBlock 数据 | 经 bsbsb.top 镜像 | **未核实** | 代码里作为「社区标记」来源，属上游既有实现，本次未新增依赖 |

## 4. 运行时/构建依赖（不随仓库分发）

| 组件 | 许可 | 说明 |
| --- | --- | --- |
| HarmonyOS Command Line Tools 26.0.0.865 | 华为开发者协议 | 本机用于 hvigorw / ohpm / codelinter，不提交二进制 |
| Microsoft Build of OpenJDK 17 | GPLv2 + Classpath Exception | 仅本机构建用（HAP 打包器需要 java） |
| 仓颉 SDK 1.2.0（windows-x64） | 随 SDK 的 LICENSE 文件 | 仅本机编译 cangjie/，产物为本地 .dll，未提交 |
| Flutter SDK 3.47.6 | BSD-3-Clause | 仅本机分析/测试用 |
| @ohos/flutter_ohos（引擎 har） | — | 仓库内是**离线桩**（harmony/flutter_ohos/），真机构建需替换为官方引擎 har；桩代码为本仓库自写 |

## 5. 生态参考实现（未复制代码，仅参考做法）

| 项目 | 地址 | 许可 | 参考点 |
| --- | --- | --- | --- |
| OpenHarmony Flutter | <https://gitee.com/openharmony-sig/flutter_flutter> | **BSD-3-Clause-Clear**（Gitee API 已验证） | Flutter 在鸿蒙上的工程形态与 FlutterPage 承载方式 |
| OpenHarmony Flutter Engine | <https://gitee.com/openharmony-sig/flutter_engine> | **BSD-3-Clause**（Gitee API 已验证） | 引擎 har 的来源与构建方式 |
| Flutter Hero / PageRouteBuilder | <https://api.flutter.dev/flutter/widgets/Hero-class.html> | BSD-3-Clause（Flutter 本体） | 容器转场的坐标语义与自动反向 |

## 6. 本次适配新增代码的归属

- 新增文件（lib/features/create/**、lib/features/ads/**、lib/core/presentation/immersive_*、
  lib/shared/ui/cover_flight.dart、harmony/**、cangjie/**、verify/**、docs/**）由本适配撰写；
- 它们与上游代码同处一个仓库、同一许可状态（上游未声明 → 保留所有权利），不单独授予额外许可；
- 若上游后续补上 LICENSE，本适配代码随之适用该许可。
