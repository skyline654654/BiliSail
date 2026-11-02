# 适配验证状态（2026-11-02）

本文件只记录**实际执行过**的检查。没有执行的一律写在「未验证」，不因代码写完而升级为通过。

## 已执行并通过

| 仓颉本机编译 | `cangjie-sdk-windows-x64-1.2.0`（SHA-256 与官网一致）+ `cjpm build` | **success**，产出 libbilicore@bilisail.dll，2 条 deprecated 警告 |

| 检查 | 方法 | 结果 |
| --- | --- | --- |
| Dart 语法与格式 | Dart SDK 3.13.7 `dart format`（`_bilisail/tools/dart-sdk`） | 18 个改动文件，0 解析错误 |
| 相对 import 完整性 | 自写扫描器遍历 `lib/` 全树解析 `import './…'` | 0 处断链 |
| 上游工程可获取 | GitHub codeload 拉取 master（50 MB）→ 解包 1808 文件 | 成功 |
| 调研取证 | gitee `openharmony/docs` + GitCode `Cangjie/cangjie_docs` raw Markdown | 各自 16 / 多份原文，逐条附 URL |

## 未验证（缺少工具链，不声称通过）

| 项 | 原因 | 补齐方式 |
| --- | --- | --- |
| `flutter analyze` / `flutter test` | 本机无 Flutter SDK；`pubspec.yaml` 依赖 media-kit 的 git overrides，需可访问 github 的 git 传输（本机 git 走 schannel 失败） | 在有 Flutter 3.47.6 的机器上跑 `tool/check.ps1` |
| ArkTS 编译与实机运行 | 无 DevEco Studio / 鸿蒙 SDK | DevEco Studio 打开 `harmony/`，`hvigorw assembleHap` |
| 仓颉 OHOS 交叉编译 | 本机只有 windows-x64 目标 SDK | 用 `cangjie-sdk-windows-x64-ohos-1.2.0` 跑 `cjpm build --target aarch64-linux-ohos` |
| 沉浸光感观感 | 需要真机 + API 26 | 真机对比 `backgroundBlurStyle` 与 `systemMaterial` |
| 投稿/发布接口 | 未做在线验证，且写操作需真实账号 | 见 `docs/api-design.md` 的登记规则，不自动重放写请求 |

## 结论口径

- 代码层面：Dart 侧已具备"可解析 + 依赖闭合"，其它语言仅"语法审查"。
- 行为层面：**没有任何一项**经过真机或运行期验证。
- 因此 README 与交付说明中不得出现"鸿蒙端已适配完成""仓颉已验证"等表述。
