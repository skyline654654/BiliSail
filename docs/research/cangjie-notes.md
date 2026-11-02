# 仓颉（Cangjie）官方文档调研笔记

> 调研日期：2026-11-02。结论取自官方站点与官方源码仓库（cangjie-lang.cn / cj-docs.gitcode.com / gitcode.com/Cangjie/*）的原始 Markdown 或 SSR 页面，逐条标注来源 URL。
> 文档版本以 **Cangjie 1.2.0（STS 通道，发布日期 2026/09/22）** 为准；LTS 通道当前为 **1.0.5（2026/02/10）**。

---

## 0. 结论摘要

1. **文档主源是 GitCode 上 `Cangjie/cangjie_docs` 仓库的 Markdown**（`docs/dev-guide/`、`docs/tools/`），由 `cj-docs.gitcode.com/zh/1.2.0/` 渲染成 HTML。取原文优先用 `https://raw.gitcode.com/Cangjie/cangjie_docs/raw/main/<path>`；扩展库 stdx 文档在 `Cangjie/cangjie_stdx` 的 `doc/libs_stdx/`。来源：<https://gitcode.com/Cangjie/cangjie_docs>、<https://gitcode.com/Cangjie/cangjie_stdx>。
2. **仓颉工程 = `cjpm.toml` + `src/` 目录树**；包是编译最小单元，模块是发布最小单元；包名必须与相对 `src/` 的目录路径一致（`.` 分隔），根目录包可省略 `package` 声明（默认包名 `default`）。来源：<https://raw.gitcode.com/Cangjie/cangjie_docs/raw/main/docs/dev-guide/source_zh_cn/package/package_name.md>。
3. **`cjpm.toml` 的权威字段表在工具手册里，比开发指南的模板更全**：除 `name/version/output-type/compile-option/src-dir/dependencies` 外，还有 `organization`、`link-option`、`override-compile-option`、`target-dir`、`script-dir`、`package-configuration`、`include/exclude`、`[workspace]`、`[ffi.c]`、`[profile]`、`[target.*]`。`output-type` 合法值只有 `"executable" | "static" | "dynamic"`。来源：<https://cj-docs.gitcode.com/zh/1.2.0/tools/source_zh_cn/cmd-tools/cjpm_manual.html>。
4. **`cjpm` 子命令 13 个**：`init / check / update / tree / build / run / test / bench / clean / bundle / publish / install / uninstall`；可执行产物落在 `target/release/bin`（或 `target/debug/bin`），单测产物在 `target/release/unittest_bin`。来源同上。
5. **C 互操作是双向的**：`foreign func` 声明调用 C；`@C func` / `CFunc` 导出给 C；调用点必须在 `unsafe` 块；仅 `CType` 家族可跨边界（`Int32/UInt8/CPointer<T>/CString/@C struct/VArray/CFunc`）。来源：<https://raw.gitcode.com/Cangjie/cangjie_docs/raw/main/docs/dev-guide/source_zh_cn/FFI/cangjie-c.md>。
6. **鸿蒙（OpenHarmony/HarmonyOS）是仓颉的一等交叉编译目标**：`aarch64-linux-ohos`、`x86_64-linux-ohos`；官方下载页直接提供 `cangjie-sdk-windows-x64-ohos-1.2.0.exe/.zip`。ArkTS↔仓颉通过 **`.d.ts` 自动生成胶水代码**（工具 `cj-dts2cj`，运行库包 `ohos.ark_interop` / `ohos.ark_interop_helper` / `ohos.base`）实现，不是手写 NAPI。来源：<https://cj-docs.gitcode.com/zh/1.2.0/dev-guide/source_zh_cn/compile_and_build/cross_compilation.html>、<https://raw.gitcode.com/Cangjie/cangjie_docs/raw/main/docs/tools/source_zh_cn/cmd-tools/cj-dts2cj-translation-rules.md>。
7. **标准库被拆成 `std` 与 `stdx` 两套**：`std` 随 SDK 自带；**JSON、HTTP、日志、TLS、MD5/SHA1/SHA256 等都在 `stdx` 扩展库里，需另行下载并配置**。任务描述中的 `std.net.http`、`std.serialization`、`encoding.json` 在 1.2.0 中并不存在，正确名字是 `stdx.net.http`、`stdx.serialization`、`stdx.encoding.json`。来源：<https://cj-docs.gitcode.com/zh/1.2.0/dev-guide/source_zh_cn/Net/net_http.html>、<https://cj-docs.gitcode.com/zh/1.2.0/libs/std/std_module_overview.html>。
8. **Windows SDK 下载页**：<https://cangjie-lang.cn/download/1.2.0>（版本选择器含 0.53.13 起的历史版本）；安装用 exe 向导，或 zip + `envsetup.ps1` / `envsetup.bat` / `envsetup.sh`；zip 方式要手工设 `CANGJIE_HOME` 与 4 条 Path。
9. **未取证项（如实标注）**：华为开发者联盟「仓颉」分册（含 HarmonyOS 工程 `AppScope/`、`entry/src/main/module.json5` 等目录规范、`@ohos.*` 具体能力清单）是客户端渲染页面，本次抓取只拿到 76 KB 空壳、无任何 `/doc/` 链接，**无法引原文**；`std` 的独立「内存管理」章节也未取到。本文不臆造这部分，见 §8。

---

## 1. 版本、入口与文档源

| 事实 | 值 | 来源 |
| --- | --- | --- |
| STS 版本 | Cangjie **1.2.0**，发布日期 **2026/09/22** | <https://cangjie-lang.cn/download/1.2.0> |
| LTS 版本 | Cangjie **1.0.5**，发布日期 **2026/02/10** | <https://cangjie-lang.cn/download/1.0.5> |
| 版本选择器历史 | 1.2.0 STS / 1.1.3 / 1.1.0 / 1.1.0-beta.25~23 / 1.0.5 / 1.0.4 / 1.0.3 / 1.0.1 / 1.0.0 / 0.53.18 / 0.53.13 | 同上（`/download` 页内嵌列表） |
| 文档站 | `https://cj-docs.gitcode.com/zh/1.2.0/...`（VitePress 构建） | <https://cangjie-lang.cn/docs> 的「开发指南」入口直接指向 `https://cj-docs.gitcode.com/zh/1.2.0/dev-guide/source_zh_cn/first_understanding/basic.html` |
| 文档源码仓 | `Cangjie/cangjie_docs`（branch `main`，目录 `docs/dev-guide`、`docs/tools`） | <https://raw.gitcode.com/Cangjie/cangjie_docs/raw/main/README_zh.md> |
| 标准库 API 文档仓 | `Cangjie/cangjie_runtime`（`stdlib/doc/libs/std/...`） | `cangjie_docs/README_zh.md`：「该文档请至 cangjie_runtime 仓库获取」 |
| 扩展库 API 文档仓 | `Cangjie/cangjie_stdx`（`doc/libs_stdx/...`） | <https://raw.gitcode.com/Cangjie/cangjie_docs/raw/main/README_zh.md> |

`cangjie_docs/README_zh.md` 原文：

> 仓颉提供如下开发者文档：
> - 仓颉编程语言开发指南：介绍仓颉语法、编译构建等内容。
> - 仓颉编程语言工具使用指南：介绍仓颉提供的工具，包括项目管理工具`cjpm` 、调试工具 `cjdb` 、格式化工具 `cjfmt` 、语言扩展工具 `HLE` 和语言服务器工具 `LSP`。
> - 仓颉编程语言标准库 API：……该文档请至 cangjie_runtime 仓库获取。
> - 仓颉编程语言扩展库 API：……该文档请至 cangjie_stdx 仓库获取。
>
> ```text
> .
> └── docs
>     ├── cmd-tools   # 该目录存放仓颉编程语言命令行工具使用指南
>     └── dev-guide   # 该目录存放仓颉编程语言开发指南
> ```
>
> 来源：<https://raw.gitcode.com/Cangjie/cangjie_docs/raw/main/README_zh.md>

（注：仓内实际路径为 `docs/tools/source_zh_cn/cmd-tools/`，README 的 `cmd-tools` 指该层目录。）

---

## 2. 项目结构与 `cjpm.toml`

### 2.1 官方给出的典型目录

```text
demo
├── src
│    ├── main.cj
│    └── pkg0
│         ├── pkg0.cj
│         ├── aoo
│         │    └── aoo.cj
│         └── boo
│              └── boo.cj
└── cjpm.toml
```

> `cjpm.toml` 是当前模块所在工作空间的配置文件，用于定义基础信息、依赖项、编译选项等内容。该文件由仓颉语言的官方项目管理工具 `cjpm` 解析和执行。
>
> **注意：** 对于同一个模块，如果需要为其配置一个有效的包，则该包所在目录必须直接包含至少一个仓颉代码文件，且其所有上级目录均需为有效包。

来源：<https://raw.gitcode.com/Cangjie/cangjie_docs/raw/main/docs/dev-guide/source_zh_cn/package/package_module_management.md>

### 2.2 `cjpm.toml` 完整字段（工具手册版，权威）

```toml
[package]                                  # 单模块配置字段，与 workspace 字段不能同时存在
    cjc-version = "1.0.0"                  # 所需 `cjc` 的最低版本要求，必需
    name = "demo"                          # 模块名及模块 root 包名，必需
    organization = ""                      # 组织名, 非必需
    description = "nothing here"           # 描述信息，非必需
    version = "1.0.0"                      # 模块版本信息，必需
    compile-option = ""                    # 额外编译命令选项，非必需
    override-compile-option = ""           # 额外全局编译命令选项，非必需
    link-option = ""                       # 链接器透传选项，可透传安全编译命令，非必需
    output-type = "executable"             # 编译输出产物类型，必需
    src-dir = ""                           # 指定源码存放路径，非必需
    target-dir = ""                        # 指定产物存放路径，非必需
    script-dir = ""                        # 指定构建脚本产物存放路径，非必需
    package-configuration = {}             # 单包配置选项，非必需
    include = ["src"]                      # 指定打包范围（gitignore 风格 glob），非必需
    exclude = ["*.txt"]                    # 指定打包排除范围（gitignore 风格 glob），非必需

    # 中心仓制品展示相关字段
    authors = ["Tom", "Joan"]
    repository = ""
    homepage = ""
    documentation = ""
    tag = []
    category = []
    license = []

[workspace]                                # 工作空间管理字段，与 package 字段不能同时存在
    members = []
    build-members = []
    test-members = []
    compile-option = ""
    override-compile-option = ""
    link-option = ""
    target-dir = ""
    script-dir = ""

[dependencies]                             # 源码依赖配置项，非必需
    aoo = "1.0.0"                                   # 导入中心仓依赖
    boo = { version = "2.0.0" }                     # 导入中心仓依赖
    coo = { git = "xxx", branch = "dev" }           # 导入 git 依赖
    doo = { path = "./pro1" }                       # 导入源码依赖

[test-dependencies]                        # 测试阶段的依赖配置项，格式和 dependencies 相同，非必需
[script-dependencies]                      # 构建脚本的依赖配置项，格式和 dependencies 相同，非必需
[replace]                                  # 依赖替换配置项，格式和 dependencies 相同，非必需

[ffi.c]                                    # 导入 C 语言的库依赖，非必需
    clib1.path = "xxx"

[profile]                                  # 命令剖面配置项，非必需
    build = {}
    test = {}
    bench = {}
    customized-option = {}

[target.x86_64-unknown-linux-gnu]          # 后端和平台隔离配置项，非必需
    compile-option = "value1"
    override-compile-option = "value2"
    link-option = "value3"

[target.x86_64-w64-mingw32.dependencies]           # 适用于对应 target 的源码依赖配置项
[target.x86_64-w64-mingw32.test-dependencies]      # 适用于对应 target 的测试阶段依赖配置项

[target.x86_64-unknown-linux-gnu.bin-dependencies] # 仓颉二进制库依赖
    path-option = ["./test/pro0", "./test/pro1"]  # 以文件目录形式配置
[target.x86_64-unknown-linux-gnu.bin-dependencies.package-option]
    "pro0.xoo" = "./test/pro0/pro0.xoo.cjo"        # 以单文件形式配置
    "pro0.yoo" = "./test/pro0/pro0.yoo.cjo"
    "pro1.zoo" = "./test/pro1/pro1.zoo.cjo"
```

来源：<https://cj-docs.gitcode.com/zh/1.2.0/tools/source_zh_cn/cmd-tools/cjpm_manual.html>（章节「模块配置文件说明」）

> 当以上字段在 cjpm.toml 中没有使用时，默认为空（对于路径，默认为配置文件所在的路径）。

**`output-type` 取值（原文表格）**

> | 输入 | 说明 |
> | --- | --- |
> | `"executable"` | 可执行程序 |
> | `"static"` | 静态库 |
> | `"dynamic"` | 动态库 |
> | 其它 | 报错 |
>
> 如果想生成 cjpm.toml 时该字段自动填充为 static，可使用命令 `cjpm init --type=static --name=modName`，不指定类型时默认生成为 executable。

**`src-dir` / `target-dir` / `script-dir`**

> `src-dir` 该字段可以指定源码的存放路径，不指定时默认为 `src` 文件夹。
> `target-dir` ……不指定时默认为 `target` 文件夹。若该字段不为空，执行 `cjpm clean` 时会删除该字段所指向的文件夹，开发者需自身保证清理该目录行为的安全性。
> `script-dir` ……不指定时默认为 `build-script-cache` 文件夹。

**`package-configuration`（按包覆盖编译参数）**

> `output-type`：包编译产物类型，取值同 output-type
> `compile-option`：仅用于该包的额外编译选项
> `combine-all-deps`：工程级编译产物合并开关，取值为 true/false，仅可配置于 root 包
>
> ```toml
> [package.package-configuration."demo.aoo"]
>     output-type = "dynamic"
>     compile-option = "-g"
> ```

**`dependencies` 三种形态（原文）**

> 要指定中心仓依赖项，请使用 version 字段。例如，下面的配置可用于导入中心仓的源码模块：
> ```toml
> [dependencies]
>     aoo = { version = "1.0.0" }
>     "org::boo" = { version = "2.0.0" }
>     coo = { version = "[1.0.0, )" }
> ```
> 同时，cjpm.toml 提供了简化的中心仓依赖配置方式：
> ```toml
> [dependencies]
>     aoo = "1.0.0"
>     "org::boo" = "2.0.0"
>     coo = "[1.0.0, )"
> ```
> 要指定远程 git 依赖项，请使用 git 字段……最多可以有一个 branch、tag 和 commitId 字段……优先级顺序为 `commitId > branch > tag`。
> ```toml
> [dependencies]
>     pro0 = { git = "https://github.com/example", tag = "v1.0.0"}
>     pro1 = { git = "https://gitee.com/example", branch = "dev"}
> ```

补充（同页）：

> `dependencies` 字段可以通过 `output-type` 属性指定编译产物类型……仅能为 `static` 或者 `dynamic`，如下所示：
> ```toml
> [dependencies]
>     pro0 = { path = "./pro0", output-type = "static" }
>     pro1 = { git = "https://gitee.com/example", output-type = "dynamic" }
> ```

**开发指南侧的精简模板**（字段少一些，可作最小可用示例；`cjpm_manual` 是超集）

来源：<https://raw.gitcode.com/Cangjie/cangjie_docs/raw/main/docs/dev-guide/source_zh_cn/compile_and_build/cjpm_usage.md>

### 2.3 `cjpm` 命令

`cjpm -h`：

```text
Cangjie Project Manager

Usage:
    cjpm [subcommand] [option]

Available subcommands:
    init       Init a new cangjie module
    check      Check the dependencies
    update     Update cjpm.lock
    tree       Display the package dependencies in the source code
    build      Compile the current module
    run        Compile and run an executable product
    test       Unittest a local package or module
    bench      Run benchmarks in a local package or module
    clean      Clean up the target directory
    bundle     Make distributable tarball of current module
    publish    Publish a module to central repository
    install    Install a cangjie binary
    uninstall  Uninstall a cangjie binary

Available options:
    -h, --help     help for cjpm
    -v, --version  version for cjpm
```

各命令要点（均摘自 <https://cj-docs.gitcode.com/zh/1.2.0/tools/source_zh_cn/cmd-tools/cjpm_manual.html>）：

- **init**：创建 `cjpm.toml` 与 `src/`；`--workspace` 建工作空间、`--name`、`--path`、`--type=<executable|static|dynamic>`、`--experimental`（多平台项目）。
- **build**：调用 `cjc` 构建；`-i` 增量、`-j <N>` 并行、`-g` debug、`--coverage`、`--cfg`、`-m <member>`、`--target <triple>`、`--target-dir`、`-o/--output`、`-l/--lint`、`--mock`、`--skip-script`。
  > 编译生成的中间文件默认会存放在 `target` 文件夹，而可执行文件会根据编译模式存放到 `target/release/bin` 或 `target/debug/bin` 文件夹。
  > 为了提供可复制的构建，此命令会创建 `cjpm.lock` 文件……如果有必要保证每个项目参与者都有可复制的构建，那么此文件应提交到版本控制系统中。
- **run**：默认先 build；`--name`、`--skip-build`、`--build-args`、`-- <values>` 透传。
- **test**：编译并运行单元测试，产物默认 `target/release/unittest_bin`；可指定单包路径 `cjpm test path1 path2`；测试文件命名 `xxx_test.cj`。
- **clean**：清理 `target`；`-g` 只清 debug；`--target-dir`；会一并清理 `cov_output` 与 `*.gcno/*.gcda`。
- **check / update / tree**：依赖检查、`cjpm.lock` 更新（`cangjie-repo.toml` 存在时更新中心仓索引）、包依赖树（`--depth`、`-p`、`--invert`、`--verbose`）。
- **bundle / publish / install / uninstall**：打包成中心仓制品、上传中心仓、安装（本地 `--path` / `--git` / 中心仓 `org::name-version`）、卸载。
- Windows 注意：
  > cjpm 在 Windows 平台暂不支持在中文路径下使用，如果遇到问题，请通过修改目录名规避。

---

## 3. 源文件组织：`package` / 目录 / `import`

### 3.1 包与模块

> 在仓颉编程语言中，包是**编译的最小单元**，每个包可以单独输出 AST 文件、静态库文件、动态库文件等产物。每个包有自己的名字空间，在同一个包内不允许有同名的顶层定义或声明（函数重载除外）。一个包中可以包含多个源文件。
>
> 模块是若干包的集合，是第三方开发者**发布的最小单元**。一个模块的程序入口只能在其根目录下，它的顶层最多只能有一个作为程序入口的 `main`，该 `main` 没有参数或参数类型为 `Array<String>`，返回类型为整数类型或 `Unit` 类型。

来源：<https://raw.gitcode.com/Cangjie/cangjie_docs/raw/main/docs/dev-guide/source_zh_cn/package/package_overview.md>

### 3.2 `package` 声明规则

```cangjie
package pkg1              // root 包 pkg1
package pkg1.sub1         // root 包 pkg1 的子包 sub1
package org1::pkg1.sub1   // org1 组织名 的 root 包 pkg1 的子包 sub1
```

> - 包声明必须在源文件的非空非注释的首行，且同一个包中的不同源文件的包声明必须保持一致。
> - 当前 Windows 平台版本，组织名、包名暂不支持使用 Unicode 字符，必须是一个仅含 ASCII 字符的合法的普通标识符。
> - 仓颉的包名需反映当前源文件相对于项目源码根目录 `src` 的路径，并将其中的路径分隔符替换为小数点。
> - **包所在的文件夹名必须与包名一致。**
> - **源码根目录默认名为 `src`。**
> - **源码根目录下的包可以没有包声明，此时编译器将默认为其指定包名 `default`。**
> - 包声明不能引起命名冲突：子包不能和当前包的顶层声明同名。

目录 ↔ 包名示例（原文）：

```text
src
|-- directory_0
    |-- directory_1
    |    |-- a.cj
    |    |-- b.cj
    |-- c.cj
|-- main.cj
```

```cangjie
// a.cj / b.cj
package default.directory_0.directory_1

// c.cj
package default.directory_0

// main.cj —— 模块根目录下可省略包声明
main(): Int64 {
    return 0
}
```

来源：<https://raw.gitcode.com/Cangjie/cangjie_docs/raw/main/docs/dev-guide/source_zh_cn/package/package_name.md>

### 3.3 程序入口 `main`

> 如果模块采用生成可执行文件的编译方式，编译器只在源文件根目录下的顶层查找 `main`。……`main` 不可被访问修饰符修饰，当一个包被导入时，包中定义的 `main` 不会被导入。
> 作为程序入口的 `main` 可以没有参数或参数类型为 `Array<String>`，返回值类型为 `Unit` 或整数类型。

```cangjie
main(): Int64 { return 0 }

main(args: Array<String>): Unit {
    for (arg in args) {
        println(arg)
    }
}
```

来源：<https://raw.gitcode.com/Cangjie/cangjie_docs/raw/main/docs/dev-guide/source_zh_cn/package/entry.md>

### 3.4 `import` 规则

```cangjie
package a

import std.math.*
import package1.foo
import {package1.foo, package2.bar}
import package1.{foo, bar, fuzz}
import package1.*
import org::package1.foo                  // 组织 org 下 package1 包中的子包 foo
import org::{package1.*, package2.*}
import p1 as A                            // 包别名
import pkgc.f1 as a                       // 声明别名
```

> - 导入语句在源文件中的位置必须在包声明之后，其他声明或定义之前。
> - 导入的成员的作用域级别低于当前包声明的成员。
> - 只允许导入当前文件可见的顶层声明或定义……
> - 禁止通过 `import` 导入当前源文件所在包的声明或定义。
> - 禁止包间的循环依赖导入，如果包之间存在循环依赖，编译器会报错。
> - `::` 后必须接包名。
> - 使用完整包名访问导入成员时，不能使用组织名。
> - 隐式导入 `core` 包：`String`、`Range` 等能直接使用是因为编译器自动隐式导入 `core` 包中所有 `public` 声明。
> - `import` 可被 `private`（默认）/`internal`/`protected`/`public` 修饰，`public|protected|internal import` 会**重导出**；但**包不可以被重导出**（`public import a.b` 报错）。

来源：<https://raw.gitcode.com/Cangjie/cangjie_docs/raw/main/docs/dev-guide/source_zh_cn/package/import.md>

---

## 4. C 互操作（`foreign func` / `@C` / `unsafe` / `CPointer` / `CString`）

来源（本节全部原文）：<https://raw.gitcode.com/Cangjie/cangjie_docs/raw/main/docs/dev-guide/source_zh_cn/FFI/cangjie-c.md>

### 4.1 仓颉调用 C

```cangjie
// declare the function by `foreign` keyword, and omit `@C`
foreign func rand(): Int32

foreign func printf(fmt: CString, ...): Int32

main() {
    // call this function by `unsafe` block
    let r = unsafe { rand() }
    println("random number ${r}")
    unsafe {
        var fmt = LibC.mallocCString("Hello, No.%d\n")
        printf(fmt, 1)
        LibC.free(fmt)
    }
}
```

关键约束（原文列表）：

1. `foreign` 修饰函数声明，代表该函数为外部函数。被 `foreign` 修饰的函数只能有函数声明，不能有函数实现。
2. `foreign` 声明的函数，参数和返回类型必须符合 C 和仓颉数据类型之间的映射关系。
3. 调用 `foreign` 修饰的函数需要被 `unsafe` 块包裹，否则编译错误。
4. `@C` 修饰的 `foreign` 关键字只能用来修饰函数声明。
5. `@C` 只支持修饰 `foreign` 函数、顶层作用域中的非泛型函数和 `struct` 类型。
6. `foreign` 函数不支持命名参数和参数默认值；允许变长参数 `...`（只能在最后，需满足 `CType`）。
7. 仓颉（CJNative 后端）提供栈扩容，但 C 侧栈大小无法感知，仍存在栈溢出风险，需按实际修改 `cjStackSize`。

### 4.2 `unsafe`

> - `unsafe` 可以修饰函数、表达式，也可以修饰一段作用域。
> - 被 `@C` 修饰的函数，被调用处需要在 `unsafe` 上下文中。
> - 在调用 `CFunc` 时，使用处需要在 `unsafe` 上下文中。
> - `foreign` 函数在仓颉中进行调用，被调用处需要在 `unsafe` 上下文中。
> - 当被调用函数被 `unsafe` 修饰时，被调用处需要在 `unsafe` 上下文中。

### 4.3 导出给 C：`@C` 函数与 `CFunc`

> 仓颉中的 `CFunc` 指可以被 C 语言代码调用的函数，共有以下三种形式：
> 1. `@C` 修饰的 `foreign` 函数
> 2. `@C` 修饰的仓颉函数
> 3. 类型为 `CFunc` 的 `lambda` 表达式（不能捕获变量）

```cangjie
// Case 1
foreign func free(ptr: CPointer<Int8>): Unit

// Case 2 —— 仓颉侧定义、C 侧可调用
@C
func callableInC(ptr: CPointer<Int8>) {
    print("This function is defined in Cangjie.")
}

// Case 3
let f1: CFunc<(CPointer<Int8>) -> Unit> = {
    ptr => print("This function is defined with CFunc lambda.")
}
```

C 侧回调：

```c
typedef void (*callback)(int);
void set_callback(callback cb);
```

```cangjie
foreign func set_callback(cb: CFunc<(Int32) -> Unit>): Unit

@C
func myCallback(s: Int32): Unit {
    println("handle ${s} in callback")
}

main() {
    unsafe { set_callback(myCallback) }
    let f: CFunc<(Int32) -> Unit> = {i => println("handle ${i} in callback")}
    unsafe { set_callback(f) }
}
```

> **注意：** `foreign` 修饰的函数与 `@C` 修饰的函数，这两种 `CFunc` 的命名不建议使用 `CJ_`（不区分大小写）作为前缀，否则可能与标准库及运行时等编译器内部符号出现冲突，导致未定义行为。

**导出符号的工程含义**（由上述语义推导，非原文）：`@C func foo(...)` 生成符合 C 调用约定的符号，配合 `--output-type=staticlib|dylib` 即可被 C / ArkTS / 任意 FFI 宿主按 C ABI 调用；参数与返回值只能用 `CType` 家族。

### 4.4 调用约定

> 仓颉编程语言通过 `@CallingConv` 来表示调用约定，目前只支持 `CDECL`……通过 C 语言互操作机制调用的 C 函数，未指定调用约定时将采用默认的 `CDECL` 调用约定。
> `@CallingConv` 只能用于修饰 `foreign` 块、单个 `foreign` 函数和顶层作用域中的 `CFunc` 函数。

```cangjie
@CallingConv[CDECL] // Can be omitted in default.
foreign func rand(): Int32
```

### 4.5 `inout` 引用传值

> - 仅可用于对 `CFunc` 的调用处。
> - 其修饰对象的类型必须满足 `CType` 约束，但不可以是 `CString`。
> - 其修饰对象不可以是用 `let` 定义的，不可以是字面量、入参、其他表达式的值等临时变量。
> - 通过仓颉侧引用传值表达式传递到 C 侧的指针，仅保证在函数调用期间有效。

```cangjie
var n: Int32 = 0
unsafe {
    foo1(inout n)          // OK
    foo1(inout data.n)     // OK（struct 成员）
    foo1(inout a.data.n)   // Error：间接来自 class 实例成员
}
```

### 4.6 类型映射

| Cangjie Type | C Type | Size (byte) |
|:---:|:---:|:---:|
| `Unit` | `void` | 0 |
| `Bool` | `bool` | 1 |
| `UInt8` | `char` / `uint8_t` | 1 |
| `Int8` | `int8_t` | 1 |
| `Int16` / `UInt16` | `int16_t` / `uint16_t` | 2 |
| `Int32` / `UInt32` | `int32_t` / `uint32_t` | 4 |
| `Int64` / `UInt64` | `int64_t` / `uint64_t` | 8 |
| `IntNative` / `UIntNative` | `ssize_t` / `size_t` | platform dependent |
| `Float32` / `Float64` | `float` / `double` | 4 / 8 |

> `int` 类型、`long` 类型等由于其在不同平台上的不确定性，需要程序员自行指定对应仓颉编程语言类型。在 C 互操作场景中，与 C 语言类似，`Unit` 类型仅可作为 `CFunc` 中的返回类型和 `CPointer` 的泛型参数。

**`@C struct`**

```cangjie
@C
struct Point3D {
    var x: Int64 = 0
    var y: Int64 = 0
    var z: Int64 = 0
}
```

> 用 `@C` 修饰的 `struct` 必须满足：成员变量类型满足 `CType`；不能实现或扩展 `interfaces`；不能作为 `enum` 的关联值类型；不允许被闭包捕获；不能具有泛型参数。用 `@C` 修饰的 `struct` 自动满足 `CType` 约束。

**指针 `CPointer<T>`**

```cangjie
foreign func malloc(size: UIntNative): CPointer<Unit>
foreign func free(ptr: CPointer<Unit>): Unit

main() {
    let p1 = CPointer<Point3D>()      // null 指针
    if (p1.isNull()) { print("p1 is a null pointer") }
    var p2 = unsafe { malloc(24) }
    var p3 = unsafe { CPointer<Point3D>(p2) }    // 指针类型转换
    unsafe { p3.write(Point3D(1, 2, 3)) }
    let p4: Point3D = unsafe { p3.read() }
    let p5: CPointer<Point3D> = unsafe { p3 + 1 } // 指针偏移
    unsafe { free(p2) }
}
```

**数组 `VArray`**

```cangjie
foreign func cfoo1(a: CPointer<Int32>): Unit
foreign func cfoo2(a: VArray<Int32, $3>): Unit

var a: VArray<Int32, $3> = [1, 2, 3]
unsafe {
    cfoo1(inout a)
    cfoo2(inout a)
}
```

> `VArray` 不允许作为 `CFunc` 的返回值类型。仓颉不支持包含柔性数组（flexible array）的结构体映射。

**字符串 `CString`**（原文成员函数清单）

> - `init(p: CPointer<UInt8>)` 通过 CPointer 构造
> - `func getChars(): CPointer<UInt8>`
> - `func size(): Int64` / `isEmpty()` / `isNotEmpty()` / `isNull()`
> - `startsWith` / `endsWith` / `equals` / `equalsLower` / `compare`
> - `subCString(start[, len])`
> - `func toString(): String`
> - `func asResource(): CStringResource`
>
> 将 `String` 类型转换为 `CString` 类型，可以通过调用 LibC 中的 `mallocCString` 接口，使用完成后需要对 `CString` 进行释放。

```cangjie
foreign func strlen(s: CString): UIntNative

main() {
    var s1 = unsafe { LibC.mallocCString("hello") }
    let t1: Int64 = s1.size()
    let length = unsafe { strlen(s1) }
    unsafe { LibC.free(s1) }
}
```

**`sizeOf` / `alignOf`**

```cangjie
public func sizeOf<T>(): UIntNative where T <: CType
public func alignOf<T>(): UIntNative where T <: CType
```

**`CType`**

> `CType` 接口本身不包含任何方法，它可以作为所有 C 互操作支持的类型的父类型，便于在泛型约束中使用。
> 1. `CType` 接口本身不满足 `CType` 约束；2. 不允许被继承、扩展；3. 不会突破子类型的使用限制。

### 4.7 编译/链接 C 库

> - `--library-path <value>`, `-L <value>`：指定要链接的库文件所在的目录。
> - `--library <value>`, `-l <value>`：指定要链接的库文件（格式 `lib[arg].[extension]`）。

官方示例：

```shell
cjc -L . -l draw ./main.cj
LD_LIBRARY_PATH=.:$LD_LIBRARY_PATH ./main
```

C 字符串示例的构建方式（原文）：

> 编译方式：先将 C 代码编译成静态库或动态库，然后编译仓颉代码并链接 C 库。
> 使用 gcc 命令 `gcc -fPIC -shared test.c -o libtest.so`，编出 C 库 `libtest.so`。
> 使用 cjc 命令 `cjc -L . -l test test.cj`，编出可执行文件 `main`。

来源：<https://raw.gitcode.com/Cangjie/cangjie_docs/raw/main/docs/dev-guide/source_zh_cn/FFI/cangjie-c.md>、CString 示例页 <https://cj-docs.gitcode.com/zh/1.2.0/libs/std/core/core_samples/core_cstring_sample.html>

```cangjie
// CStringResource 自动管理内存（原文示例节选）
let cs = unsafe { LibC.mallocCString("CString in Cangjie code.") }
try (csr = cs.asResource()) {
    unsafe { printCString(csr.value) }
    0
}
```

### 4.8 跨语言调用的运行期约束（原文）

> - 线程局部变量：仓颉线程被调度到哪个操作系统线程是随机的，从而在仓颉线程上调用其他语言的线程局部变量是有风险的。
> - 线程绑定：线程优先级和线程亲和性等与线程绑定的行为不建议使用。
> - 同步原语：不建议在其他语言中出现可能导致长时间等待的阻塞性行为。
> - fork：在 C 语言中以 `fork()` 方式创建子进程，子进程中不支持执行仓颉逻辑。
> - 进程退出：在 C 语言中退出进程，进程内共享的资源已经释放，可能导致非法访问等错误。

---

## 5. 与 ArkTS / 鸿蒙互操作

### 5.1 鸿蒙是官方交叉编译目标

来源：<https://cj-docs.gitcode.com/zh/1.2.0/dev-guide/source_zh_cn/compile_and_build/cross_compilation.html>

原文表格（节选）：

> | 编译平台 | 目标平台 | 常用场景/工具 | 对应 SDK 安装包 |
> | --- | --- | --- | --- |
> | Windows (x64) | OpenHarmony/HarmonyOS | OpenHarmony/HarmonyOS 设备或模拟器 | 请至鸿蒙开发者官网进一步了解。 |
> | macOS (aarch64) | OpenHarmony/HarmonyOS | OpenHarmony/HarmonyOS 设备或模拟器 | 请至鸿蒙开发者官网进一步了解。 |
> | Linux (x64) | OpenHarmony/HarmonyOS | OpenHarmony/HarmonyOS 设备或模拟器 | 请至鸿蒙开发者官网进一步了解。 |
> | Windows (x64) | Android (aarch64) | Android 真机 | `cangjie-sdk-windows-x64-android.x.y.z.zip`（或 `.exe`） |

目标三元组：

> | 编译目标名称 | 其他别名 | 说明 |
> | --- | --- | --- |
> | `x86_64-linux-ohos` | `x86_64-unknown-linux-ohos` | x86_64 架构 OpenHarmony/HarmonyOS 平台 |
> | `aarch64-linux-ohos` | `aarch64-unknown-linux-ohos`, `arm64-unknown-linux-ohos`, `arm64-linux-ohos` | aarch64 架构 OpenHarmony/HarmonyOS 平台 |
> | `aarch64-linux-android<integer>` | … | aarch64 架构 Android 平台 |

配合 `cjpm build --target <triple>` 使用（见 §2.3）。

### 5.2 官方下载页给出的 ohos SDK 包（直接证据）

来源：<https://cangjie-lang.cn/download/1.2.0>

```text
Cangjie 1.2.0      发布日期 2026/09/22

Windows 软件包
cangjie-sdk-windows-x64-1.2.0.exe                92.99MB
cangjie-sdk-windows-x64-1.2.0.zip                250.7MB
cangjie-sdk-windows-x64-android-1.2.0.exe        142.03MB
cangjie-sdk-windows-x64-android-1.2.0.zip        346.75MB
cangjie-sdk-windows-x64-ohos-1.2.0.exe           133.27MB
cangjie-sdk-windows-x64-ohos-1.2.0.zip           344.43MB

Mac 软件包
cangjie-sdk-mac-aarch64-1.2.0.tar.gz             156.2MB
cangjie-sdk-mac-aarch64-ios-1.2.0.tar.gz         282.42MB
cangjie-sdk-mac-aarch64-android-1.2.0.tar.gz     249.22MB
cangjie-sdk-mac-aarch64-ohos-1.2.0.tar.gz        198.48MB

Linux 软件包
cangjie-sdk-linux-x64-1.2.0.tar.gz               192.26MB
cangjie-sdk-linux-aarch64-1.2.0.tar.gz           193.27MB
cangjie-sdk-linux-x64-ohos-1.2.0.tar.gz          271.79MB
cangjie-sdk-linux-x64-android-1.2.0.tar.gz       248.12MB

IDE
cangjie-1.2.0.vsix                               5.32MB   (VScode Plugin)
```

即：**Windows 上做鸿蒙仓颉开发，装 `cangjie-sdk-windows-x64-ohos-<ver>.exe`（或 zip）**。

### 5.3 ArkTS ↔ 仓颉：由 `.d.ts` 生成胶水代码（官方机制）

来源：<https://raw.gitcode.com/Cangjie/cangjie_docs/raw/main/docs/tools/source_zh_cn/cmd-tools/cj-dts2cj-translation-rules.md>

生成代码的 import 头部固定为：

```cangjie
import ohos.ark_interop.*
import ohos.ark_interop_helper.*
import ohos.base.*
```

全局函数映射（原文示例）：

```typescript
// 输入 .d.ts
declare function greeter(fn: (a: string) => void): void;
declare function printToConsole(s: string): void;
```

```cangjie
// 生成的仓颉代码
public func greeter(fn: (a: String) -> Unit): Unit {
    hmsGlobalApiCall<Unit>("_ark_interop_api", "greeter", { ctx => [ctx.function({ ctx, info =>
        let p0 = String.fromJSValue(ctx, info[0])
        fn(p0)
        ctx.undefined().toJSValue()
    }).toJSValue()] })
}

public func printToConsole(s: String): Unit {
    hmsGlobalApiCall<Unit>("_ark_interop_api", "printToConsole", { ctx => [s.toJSValue(ctx)] })
}
```

接口/成员函数映射（原文示例，注意**跨线程切主线程**的 `checkThreadAndCall`）：

```cangjie
public class Person {
    protected Person(let arkts_object: JSObject) {}

    public mut prop name: String {
        get() {
            checkThreadAndCall<String>(getMainContext()) {
                ctx: JSContext => String.fromJSValue(ctx, arkts_object["name"])
            }
        }
        set(v) {
            checkThreadAndCall<Unit>(getMainContext()) {
                ctx: JSContext => arkts_object["name"] = v.toJSValue(ctx)
            }
        }
    }

    public func greet(): String {
        jsObjApiCall<String>(arkts_object, "greet", emptyArg)
    }
}
```

支持矩阵（原文表格，节选）：

> | `.d.ts` | 支持范围 | 规格约束 |
> | --- | --- | --- |
> | 命名空间 | 无 | 不支持 |
> | 全局函数 | 支持重载，支持泛型函数 | |
> | 全局变量 | 需要用户手动修改成正确的初始化值 | 不支持泛型类型全局变量 |
> | 接口 | 基本类型接口、可选属性、只读属性、成员函数、泛型、函数重载、数组类型、继承、嵌套对象 | 不支持索引签名、动态属性、函数类型、构造函数、声明合并 |
> | 类 | 构造函数、静态成员、私有/保护成员、泛型成员、抽象类、实现接口、继承、重载方法 | 不支持带装饰器类、带命名空间的类型 |
> | 枚举 | 字符串/数字/常量/异构枚举 | 不支持计算值枚举 |
> | 导入 | 支持（但生成的代码是注释形式，需用户确认重写） | 导出不支持 |

运行库关键类型/函数（全部出自生成代码，可作为 API 参考）：`JSContext`、`JSValue`、`JSObject`、`JSInteropType`、`toJSValue(ctx)` / `fromJSValue(ctx, v)`、`hmsGlobalApiCall<T>`、`jsObjApiCall<T>`、`checkThreadAndCall<T>(getMainContext())`、`emptyArg`、`getClassConstructorObj`、`context.function/object/string/number/boolean/null/undefined/arrayBuffer/bigint`、`Promise<T>`。

配套还有 **C → 仓颉** 的胶水生成（HLE）：

> HLE 自动生成 C 语言到仓颉的胶水代码，支持函数、结构体、枚举和全局变量的翻译，类型支持：基础类型、结构体类型、指针、数组和字符串。

来源：<https://raw.gitcode.com/Cangjie/cangjie_docs/raw/main/docs/tools/source_zh_cn/cmd-tools/cj-c2cj-translation-rules.md>（该文把 `short` 映射为 `Int64`，与 FFI 文档的 `Int16↔int16_t` 不一致，见 §8。）

### 5.4 仓颉三方库（中心仓）与鸿蒙打包约束

- **中心仓**：<https://pkg.cangjie-lang.cn/index>（标题「中心仓」）；依赖写法见 §2.2 `[dependencies] version`；发布 `cjpm publish`、安装 `cjpm install org::boo-2.0.0`。
- **社区库组织**：<https://gitcode.com/Cangjie-TPC>，可见仓库包括 `CangjieMagic`、`markdown4cj`、`httpclient4cj`、`CJson`、`zip4cj`、`zlib4cj`、`mail4cj`、`prism4cj`、`cbc-engine` 等。
- **stdx 的平台分发**（`downloader.ps1/sh` 支持 `ohos-aarch64`、`ohos-x64`）：

  ```powershell
  irm https://raw.gitcode.com/Cangjie/cangjie_stdx/raw/main/downloader.ps1 -OutFile "$env:TEMP\downloader.ps1"; & "$env:TEMP\downloader.ps1" 1.0.0.1 -p windows-x64 -d C:\cangjie_libs
  ```

  来源：<https://raw.gitcode.com/Cangjie/cangjie_stdx/raw/main/README_zh.md>

- **HarmonyOS 上的 stdx 打包规则（重要工程约束）**，原文（stdx.crypto.digest 总览）：

  > - 对于 HarmonyOS 操作系统，可参考以下方式：
  >   - 由于 HarmonyOS 6.0 及以上版本系统限制，stdx 无法直接调用系统内置的 OpenSSL，需要用户自行编译 HarmonyOS 的 OpenSSL 动态库并打包到应用中；
  >   - 编译 HarmonyOS 的 OpenSSL 可参考 [OHOS 仓颉 SDK 构建指导书](https://gitcode.com/Cangjie/cangjie_build/blob/main/docs/linux_ohos_toolchain.md)；
  >   - 将编译好的动态库文件 `libcrypto_openssl.z.so` 和 `libssl_openssl.z.so` 拷贝到应用模块的 `libs/arm64-v8a`（真机）或 `libs/x86_64`（模拟器）目录下，DevEco Studio 会将其打包到应用包的对应目录中……
  >   - 另外，使用 **DevEco Studio-Cangjie Plugin（26.0.0 Beta1 及以上版本）** 时，在动态链接 stdx 库的场景下，还需要把 stdx 模块中的 `libcangjie-dynamicLoader-opensslFFI.so` 打包到应用包中……

  来源：<https://raw.gitcode.com/Cangjie/cangjie_stdx/raw/main/doc/libs_stdx/crypto/digest/crypto_digest_package_overview.md>

  由这段可确证：**鸿蒙上的仓颉应用由 DevEco Studio + Cangjie Plugin 构建，模块级原生库放在 `libs/<abi>/`**。

- **std 支持矩阵含鸿蒙**：

  > | OpenHarmony | aarch64 | OpenHarmony 5.1 或更高版本 |
  > | OpenHarmony | arm32 | OpenHarmony 5.1 或更高版本 |
  > | OpenHarmony | x86_64 | OpenHarmony 5.1 或更高版本 |
  > | HarmonyOS | aarch64 | HarmonyOS 5.1 或更高版本 |

  来源：<https://cj-docs.gitcode.com/zh/1.2.0/libs/std/std_module_overview.html>

> ⚠️ 未能取证：`AppScope/app.json5`、`entry/src/main/module.json5`、`oh-package.json5`、`build-profile.json5` 这一级鸿蒙工程目录规范，以及 `@ohos.*`（如 `@ohos.net.http`）在仓颉侧的具体包名清单。见 §8。

---

## 6. 标准库要点

### 6.1 std / stdx 的分界（必须先弄清）

`std` 包含：`core / argopt / ast / binary / collection / collection.concurrent / console / convert / crypto.cipher / crypto.digest / database.sql / deriving / env / fs / interop / io / math / math.numeric / net / objectpool / overflow / posix / process / random / ref / reflect / regex / runtime / sort / sync / time / unicode / unittest(…mock/testmacro/diff/prop_test)`。

来源：<https://cj-docs.gitcode.com/zh/1.2.0/libs/std/std_module_overview.html>

`stdx`（扩展库，需单独下载）包含：`actors / aspect_cj / compress / crypto / effect / encoding(base64|hex|json|json_stream|url) / log / logger / net(http|tls) / serialization / syntax / string_intern / unittest(扩展)`。

来源：<https://raw.gitcode.com/Cangjie/cangjie_stdx/raw/main/README_zh.md>

**官方明确写了「net、log 已移到 stdx」**：

> **说明：** net、log 等库已从仓颉 SDK 移到 stdx 模块，使用前需要下载软件包，并在 `cjpm.toml` 中配置。

来源：<https://raw.gitcode.com/Cangjie/cangjie_docs/raw/main/docs/dev-guide/source_zh_cn/Net/net_http.md>

### 6.2 `String`

三种字面量：单行（`"..."`/`'...'`）、多行（`"""..."""`/`'''...'''`）、多行原始（`#"..."#`、`##'...'##`）。插值 `"${expr}"`，`{}` 内可用 `;` 串多句。

```cangjie
let fruit = "apples"
let count = 10
let s = "There are ${count * count} ${fruit}"
let area = "The area of a circle with radius ${r} is ${let PI = 3.141592;PI * r * r}"
```

支持 `==` 比较、`+` 拼接、`contains` / `split` 等：

```cangjie
var s1 = "abc"
var s2 = "ABCabc"
var s3 = "abcyyabcqqabcbc"
let r1 = s2.contains(s1)   // true
let r2 = s3.split(s1)
s1 = s2
```

字符串 ↔ 字节：`String.fromUtf8(Array<UInt8>)`、`s.toArray()`（见 §6.6 示例）。

来源：<https://cj-docs.gitcode.com/zh/1.2.0/dev-guide/source_zh_cn/basic_data_type/strings.html>

### 6.3 内存与资源

可取证的只有以下机制（未取到独立的「内存管理」章节，不臆造 GC 细节）：

- `core` 提供 `Resource` 体系与 `try (res = x.asResource()) { ... }` 自动释放，用于 `CString` 等原生资源（§4.7 示例）。
- 原生内存显式申请/释放：`LibC.malloc<T>()` / `LibC.mallocCString()` / `LibC.free()`，均在 `unsafe` 中。
- `std.objectpool`：

  > 在面向对象语言中，对象的申请和释放普遍实现复杂，耗时较长……仓颉对象的申请和释放也面临同样的问题。对象池通过缓存、复用对象，减少对象的申请和释放，有效提高程序性能。
  > 由于 `ObjectPool` 在实现中根据仓颉线程 id 进行存取，将导致存和取分布在不同仓颉线程的情况下，存入的对象难以被取到。

  来源：<https://cj-docs.gitcode.com/zh/1.2.0/libs/std/objectpool/objectpool_package_overview.html>
- `std.sync`（`Atomic`/`Monitor`/`Timer`）、`spawn` 线程（见 §6.5 HTTP 示例）。

### 6.4 JSON：`stdx.encoding.json`

> json 包用于对 JSON 数据的处理，实现 `String`, `JsonValue`, `DataModel` 之间的相互转换。
> `JsonValue` 是对 JSON 数据格式的封装，包括 object, array, string, number, true, false 和 null。

API 列表（原文）：接口 `ToJson`；类 `JsonArray / JsonBool / JsonFloat / JsonInt / JsonNull / JsonObject / JsonString / JsonValue`；枚举 `JsonKind`；异常 `JsonException`。

来源：<https://raw.gitcode.com/Cangjie/cangjie_stdx/raw/main/doc/libs_stdx/encoding/json/json_package_overview.md>

```cangjie
import stdx.encoding.json.*

main() {
    let jsonString = ##"[true,"kjjjke\"eed",{"sdfd":"ggggg","eeeee":[341,false,{"nnnn":55.87}]},3422,22.341,false,[22,22.22,true,"ddd"],43]"##
    let jsonValue: JsonValue = JsonValue.fromStr(jsonString)
    let compactString = jsonValue.toString()      // 紧凑
    let prettyString = jsonValue.toJsonString()   // 带缩进
}
```

来源：<https://raw.gitcode.com/Cangjie/cangjie_stdx/raw/main/doc/libs_stdx/encoding/json/json_samples/json_value_sample.md>

另有流式包 `stdx.encoding.json_stream`。

### 6.5 网络：`std.net`（Socket）与 `stdx.net.http`（HTTP）

**`std.net` 只做 Socket，不做 HTTP**：

> net 包用于进行网络通信，提供启动 Socket 服务器、连接 Socket 服务器、发送数据、接收数据等功能……我们支持 UDP/TCP/UDS 三种 Socket 类型。
> 类：`IPAddress`、`IPPrefix`、`IPSocketAddress`、`IPv4Address`、`IPv6Address`、`RawSocket`、`SocketAddress`、`TcpServerSocket`、`TcpSocket`、`UdpSocket`、`UnixDatagramSocket`、`UnixServerSocket`、`UnixSocket`、`UnixSocketAddress`

来源：<https://cj-docs.gitcode.com/zh/1.2.0/libs/std/net/net_package_overview.html>

**HTTP 在 `stdx.net.http`**（`HttpRequestBuilder` / `HttpResponseBuilder`、`ServerBuilder`、`ClientBuilder`），支持 HTTP 1.0/1.1/2.0：

```cangjie
import stdx.net.http.*
import std.time.*
import std.sync.*
import stdx.log.*

let server = ServerBuilder().addr("127.0.0.1").port(0).build()

func startServer(): Unit {
    server.distributor.register("/hello", { httpContext =>
        httpContext.responseBuilder.body("Hello Cangjie!")
    })
    server.logger.level = LogLevel.OFF
    server.serve()
}

func startClient(): Unit {
    let client = ClientBuilder().build()
    let response = client.get("http://127.0.0.1:${server.port}/hello")
    let buffer = Array<Byte>(32, repeat: 0)
    let length = response.body.read(buffer)
    println(String.fromUtf8(buffer[..length]))
    client.close()
}
```

客户端最小写法与 TLS 配置：

```cangjie
import stdx.net.http.*

main() {
    let client = ClientBuilder().build()
    let response = client.get("http://example.com/hello")
    println(response)
    client.close()
}
```

```cangjie
var tlsConfig = TlsClientConfig()
let rootCertContent = String.fromUtf8(File.readFrom("/rootCerPath"))
tlsConfig.verifyMode = CustomCA(X509Certificate.decodeFromPem(rootCertContent).map({certificate => certificate}))
tlsConfig.supportedAlpnProtocols = ["h2"]
let client = ClientBuilder().tlsConfig(tlsConfig).enablePush(false).connector(customConnector).build()
```

来源：<https://raw.gitcode.com/Cangjie/cangjie_stdx/raw/main/doc/libs_stdx/net/http/http_samples/http_client.md>；包总览 <https://raw.gitcode.com/Cangjie/cangjie_stdx/raw/main/doc/libs_stdx/net/http/http_package_overview.md>

### 6.6 加密摘要：`std.crypto.digest` 只有接口，`MD5/SHA1/SHA256` 在 `stdx.crypto.digest`

**这是本次调研纠正的一处常见误解**（任务描述把 MD5/SHA 归到 `std.crypto.digest`）。

`std.crypto.digest` 公开 API 只有：接口 `Digest` + 三个泛型函数

```cangjie
public func digest<T>(algorithm: T, data: Array<Byte>): Array<Byte> where T <: Digest
public func digest<T>(algorithm: T, input: InputStream): Array<Byte> where T <: Digest
public func digest<T>(algorithm: T, data: String): Array<Byte> where T <: Digest   // deprecated
```

来源：<https://raw.gitcode.com/Cangjie/cangjie_runtime/raw/main/stdlib/doc/libs/std/crypto/digest/digest_package_api/digest_package_funcs.md>

具体算法类在 `stdx.crypto.digest`：

> digest 包提供常用的消息摘要算法，包括 MD5、SHA1、SHA224、SHA256、SHA384、SHA512、HMAC、SM3 等。

```cangjie
public class MD5 <: Digest    { public init() }
public class SHA1 <: Digest   { public init() }
public class SHA256 <: Digest { public init() }
```

可用样例（官方 verify 用例，含期望输出）：

```cangjie
import stdx.crypto.digest.*
import std.convert.*
import std.crypto.digest.*
import stdx.encoding.hex.*

main() {
    let message = "helloworld"
    let md5 = MD5()
    md5.write(message.toArray())
    let hash = md5.finish()
    println("MD5 哈希值: ${toHexString(hash)}")   // fc5e038d38a57032085441e7fe7010b0
    return 0
}
```

`SHA1("helloworld") = 6adfb183a4a2c94a2f92dab5ade762a47889a5a1`，`SHA256("helloworld") = 936a185caaa266bb9cbe981e9e05cb78cd732b0b3280eb944412bb6f8f8f07af`。

依赖：**OpenSSL 3 的 crypto 动态库**（Linux `libssl-dev`；Windows 需 `libcrypto.dll.a`/`libcrypto.lib` + `libcrypto-3-x64.dll` 并设 `LIBRARY_PATH`/`PATH`；macOS `brew install openssl@3`；HarmonyOS 6.0+ 需自行编译并打包 `.z.so`，见 §5.4）。未装会抛 `CryptoException：Can not load openssl library or function xxx`。

来源：<https://raw.gitcode.com/Cangjie/cangjie_stdx/raw/main/doc/libs_stdx/crypto/digest/crypto_digest_package_overview.md>、<https://raw.gitcode.com/Cangjie/cangjie_stdx/raw/main/doc/libs_stdx/crypto/digest/digest_samples/sample_digest.md>、<https://raw.gitcode.com/Cangjie/cangjie_stdx/raw/main/doc/libs_stdx/crypto/digest/digest_package_api/digest_package_classes.md>

---

## 7. Windows SDK 下载与安装（版本写清）

**下载页**：<https://cangjie-lang.cn/download>（总入口，三通道）→ 版本页 <https://cangjie-lang.cn/download/1.2.0>、<https://cangjie-lang.cn/download/1.0.5>。

> 仓颉编程语言提供三个版本（LTS、STS 和 Nightly Builds）……
> | 通道 | 版本 |
> | --- | --- |
> | LTS（长期稳定，更新/维护计划待定） | **1.0.5**（2026/02/10） |
> | STS（半年更新） | **1.2.0**（2026/09/22） |
> | Nightly Builds | <https://gitcode.com/Cangjie/nightly_build/releases> |

**Windows 安装（官方 install.md 原文要点）**：

> 在 Windows 平台上，仓颉为开发者提供了 `exe` 和 `zip` 两种格式的安装包……
> - 如果选择 `exe` 格式的安装包（例如 `cangjie-sdk-windows-x64-x.y.z.exe`），请直接执行此文件，跟随安装向导点击操作，即可完成安装。
> - 如果选择 `zip` 格式的安装包（例如 `cangjie-sdk-windows-x64-x.y.z.zip`），请将它解压到适当目录，在安装包中，仓颉为开发者提供了三种不同格式的安装脚本，分别是 `envsetup.bat`，`envsetup.ps1` 和 `envsetup.sh`……
>   - CMD：`path\to\cangjie\envsetup.bat`
>   - PowerShell：`. path\to\cangjie\envsetup.ps1`
>   - MSYS/bash：`source path/to/cangjie/envsetup.sh`
> - 为了验证是否安装成功，请在以上命令环境中继续执行 `cjc -v`。

zip 方式要手工配置的环境变量（原文）：

> 1. 配置 `CANGJIE_HOME`：值为解压路径，例如 `D:\cangjie`。
> 2. 配置 `Path`，加入四条：
>    `%CANGJIE_HOME%\bin`
>    `%CANGJIE_HOME%\tools\bin`
>    `%CANGJIE_HOME%\tools\lib`
>    `%CANGJIE_HOME%\runtime\lib\windows_x86_64_cjnative`
> 3. 仅当前用户：追加 `C:\Users\<user>\.cjpm\bin`。
> 4. 设置完成后可能需要重启命令行窗口或重启系统以让设置生效。

卸载：exe 安装跑安装目录下的 `unins000.exe`；zip 安装删目录 + 移除环境变量。更新需先卸载再装新版本。

> 当前 Windows 平台上的仓颉编译器基于 MinGW 实现，相较于 Linux 版本的仓颉编译器，功能会有部分欠缺。

来源：<https://raw.gitcode.com/Cangjie/cangjie_docs/raw/main/docs/dev-guide/source_zh_cn/first_understanding/install.md>（渲染页 <https://cj-docs.gitcode.com/zh/1.2.0/dev-guide/source_zh_cn/first_understanding/install.html>）

VS Code 插件：1.2.0 为 `cangjie-1.2.0.vsix`（5.32 MB）；1.0.5 为 `cangjie-vscode-1.0.5.tar.gz`。来源：两个下载页。

---

## 8. 未取证 / 存疑（不要当作结论使用）

| 项 | 现状 | 原因 |
| --- | --- | --- |
| 鸿蒙应用工程目录规范（`AppScope/app.json5`、`entry/src/main/module.json5`、`oh-package.json5`、`build-profile.json5`、`hvigorfile.ts`） | **未取证** | 属华为开发者联盟「仓颉」分册；<https://developer.huawei.com/consumer/cn/cangjie/> 抓取仅得 76 KB 空壳（无 `/doc/` 链接、无 `cangjie-guides` 字样），文档正文由客户端 JS 拉取，本次无法取得可引用的原文 |
| `@ohos.*` 在仓颉侧的包名清单（如 `ohos.net.http` 还是 `ohos.ark_interop` + JS 桥） | **仅部分取证** | 官方只给出 `ohos.ark_interop` / `ohos.ark_interop_helper` / `ohos.base` 三个包名（来自 `.d.ts` 生成代码的 import），其余未见 |
| `std` 的独立内存管理 / GC 章节 | **未取证** | 已抓取的页面不含「垃圾回收/GC/内存管理」字样；只引用了 `Resource`、`LibC.malloc/free`、`objectPool` 等可证事实 |
| `std.serialization` | **不存在** | 1.2.0 std 包列表无该包；序列化在 `stdx.serialization`（<https://raw.gitcode.com/Cangjie/cangjie_stdx/raw/main/doc/libs_stdx/serialization/serialization_package_overview.md>） |
| `std.net.http` | **不存在** | HTTP 在 `stdx.net.http`（§6.5） |
| HLE 的 `short → Int64` 映射 | **与 FFI 文档冲突** | `cj-c2cj-translation-rules.md` 写 `short → Int64`，而 FFI 文档类型表为 `Int16 ↔ int16_t`；以 FFI 文档为准，工具文档疑似笔误 |

---

## 9. BiliSail 用仓颉重写核心模块的可行路径

> 前提事实（来自本仓 `AGENTS.md`，不是仓颉文档）：BiliSail 是 Flutter/Dart 应用，根应用 + `bili_api` / `bili_player` / `bili_danmaku` / `bili_mux` 四包；当前**不依赖 Rust**；`bili_mux` 已是「Dart FFI + 本地编译原生库」的既有范式；架构边界要求 `domain` 保持纯 Dart、Repository 实现放 `data`、页面不直接发请求。

### 9.1 能接的边界只有一条：C ABI

仓颉与 Dart 之间没有官方绑定，仓颉不产出 Dart/Flutter 插件。**唯一可行通道**是：仓颉编译成 `static`/`dynamic` 库，用 `@C func` 暴露 C ABI，Dart 侧用 `dart:ffi` 调用——与现有 `bili_mux`（FFmpeg + FFI）同一形态。

- 仓颉侧导出：`@C func`（§4.3），返回/参数只能是 `CType`（§4.6）；`String` 必须降级为 `CString` 或 `(ptr: CPointer<UInt8>, len: IntNative)`。
- 仓颉侧调用已有 C 库（FFmpeg / libmpv）：`foreign func` + `unsafe`（§4.1），用 `-L/-l` 或 `[ffi.c]`。
- 产物类型：`output-type = "static"` / `"dynamic"`（§2.2）。

### 9.2 平台落点

| 目标 | 做法 | 依据 |
| --- | --- | --- |
| Windows x64（当前主开发平台） | `cangjie-sdk-windows-x64-1.2.0`，`cjc` 编 `dylib`/`staticlib`，Dart `DynamicLibrary.open("xxx.dll")` | 下载页 + §2.2 |
| Android arm64 | `cangjie-sdk-*-android-1.2.0`，`--target=aarch64-linux-android31`（需 NDK sysroot、`libclang_rt.builtins-aarch64-android.a`、工具链 bin） | §5.1 交叉编译章节 |
| OpenHarmony/HarmonyOS arm64 | `cangjie-sdk-windows-x64-ohos-1.2.0`，`--target=aarch64-linux-ohos`；应用侧原生库放 `libs/arm64-v8a`，用 DevEco Studio + Cangjie Plugin 打包 | §5.1、§5.4 |

### 9.3 建议的落地顺序（按风险从低到高）

**第一步（低风险，纯计算）**：`bili_mux` 的封装编排、`bili_danmaku` 的弹幕布局/轨道分配。
- 输入输出都是字节数组/坐标整数，天然落在 `CType`；不碰网络、不碰账号。
- 交付物：`libbilisail_core.so/.dll/.dylib` + Dart FFI 适配层，`bili_mux` 现有 `BILI_MUX_LIBRARY` 加载方式可复用。

**第二步（中风险，需要哈希）**：WBI 签名（`w_rid`）等纯哈希逻辑。
- 需要 `MD5/SHA256` → 必须引 `stdx.crypto.digest`，**随之引入 OpenSSL 3 运行时依赖**（§6.6）。Windows/Android 尚可；**HarmonyOS 6.0+ 必须自带 `.z.so` 并打进 `libs/arm64-v8a`**，这是最容易被低估的工程成本。
- 若不想背 OpenSSL，可在仓颉侧自写纯仓颉哈希实现，避免 stdx 依赖。

**第三步（高风险，不建议先做）**：网络会话（Cookie/WBI/CSRF、Protobuf、WebSocket）、播放器会话。
- 与 `AGENTS.md` 的边界冲突：`domain` 必须纯 Dart；`bili_api` 是「纯 Dart HTTP/Protobuf/WebSocket 协议层」；把网络搬进仓颉等于在 Dart 侧再造一层 FFI 协议层，收益不确定而调试成本高。
- 仓颉线程会被调度到任意 OS 线程（§4.8），若把阻塞式网络放进 FFI 调用，会占住 Dart isolate 的调用栈；需要额外线程/回调设计（`spawn` + 队列 + 完成回调 C ABI）。
- HarmonyOS 上还要解决 TLS 证书来源、`libcrypto_openssl.z.so` 打包、以及 `.z.so` 的 ABI 兼容。

### 9.4 具体注意事项清单

1. **不要跨 FFI 传托管对象**：只能传 `CType`；字符串走 `CString` 或 `Array<UInt8>` + 长度；结构体必须 `@C struct`（无泛型、无 interface、不被闭包捕获）。
2. **错误处理**：仓颉异常不能穿过 C ABI。需约定返回码 + `out` 参数（`inout` 只在调用期有效，§4.5 明确「C 侧不应该保存指针留作后用」）。
3. **内存所有权**：谁 `malloc` 谁 `free`；仓颉侧用 `LibC.mallocCString` 分配、Dart 侧调用完必须回调释放，或用 `Resource`/`try` 在仓颉侧闭环。
4. **命名冲突**：`@C` 导出符号不要用 `CJ_` 前缀（§4.3 原文警告）。
5. **构建可复现**：`cjpm.lock` 必须入库（§2.3）；`cjpm` 不支持 Windows 中文路径（§2.3）。本仓路径 `C:\Users\16857\Desktop\dsh\_bilisail\work\BiliSail-OpenHarmony` 为纯 ASCII，可用；新增子目录也不要用中文名。
6. **制品化**：`cjpm bundle` 可产出符合中心仓格式的制品包，便于把重写出的仓颉模块作为独立可发布单元管理（§2.3）。
7. **验收口径**：仓颉侧只测「C ABI + 数值正确性」；Dart 侧照现有 `tool/check.ps1` 流程；HarmonyOS 侧必须真机验证 `.so` 加载与 OpenSSL 打包，不能以「编译通过」代替。

### 9.5 一句话结论

**可行，但应限定在「纯计算 + C ABI 静态/动态库」这一层**：先做 `bili_mux` 编排与 `bili_danmaku` 布局，用 Dart FFI 接入；把网络/会话留在 Dart（`bili_api`），除非后续能拿到华为官方鸿蒙仓颉工程模板与 `@ohos` 能力清单，并愿意承担 OpenSSL 打包成本。

---

## 10. 来源清单

**官方站点 / 文档站**

- <https://cangjie-lang.cn/>（官网）
- <https://cangjie-lang.cn/docs>（文档入口，指向 cj-docs）
- <https://cangjie-lang.cn/download>、<https://cangjie-lang.cn/download/1.2.0>、<https://cangjie-lang.cn/download/1.0.5>
- <https://cj-docs.gitcode.com/zh/1.2.0/dev-guide/source_zh_cn/compile_and_build/cjpm_usage.html>
- <https://cj-docs.gitcode.com/zh/1.2.0/dev-guide/source_zh_cn/compile_and_build/cjc_usage.html>
- <https://cj-docs.gitcode.com/zh/1.2.0/dev-guide/source_zh_cn/compile_and_build/cross_compilation.html>
- <https://cj-docs.gitcode.com/zh/1.2.0/dev-guide/source_zh_cn/package/package_overview.html>
- <https://cj-docs.gitcode.com/zh/1.2.0/dev-guide/source_zh_cn/package/package_name.html>
- <https://cj-docs.gitcode.com/zh/1.2.0/dev-guide/source_zh_cn/package/package_module_management.html>
- <https://cj-docs.gitcode.com/zh/1.2.0/dev-guide/source_zh_cn/package/import.html>
- <https://cj-docs.gitcode.com/zh/1.2.0/dev-guide/source_zh_cn/package/entry.html>
- <https://cj-docs.gitcode.com/zh/1.2.0/dev-guide/source_zh_cn/FFI/cangjie-c.html>
- <https://cj-docs.gitcode.com/zh/1.2.0/dev-guide/source_zh_cn/Net/net_http.html>
- <https://cj-docs.gitcode.com/zh/1.2.0/dev-guide/source_zh_cn/basic_data_type/strings.html>
- <https://cj-docs.gitcode.com/zh/1.2.0/dev-guide/source_zh_cn/first_understanding/install.html>
- <https://cj-docs.gitcode.com/zh/1.2.0/tools/source_zh_cn/cmd-tools/cjpm_manual.html>
- <https://cj-docs.gitcode.com/zh/1.2.0/tools/source_zh_cn/cmd-tools/cj-dts2cj-translation-rules.html>
- <https://cj-docs.gitcode.com/zh/1.2.0/libs/std/std_module_overview.html>
- <https://cj-docs.gitcode.com/zh/1.2.0/libs/std/net/net_package_overview.html>
- <https://cj-docs.gitcode.com/zh/1.2.0/libs/std/objectpool/objectpool_package_overview.html>
- <https://cj-docs.gitcode.com/zh/1.2.0/libs/std/crypto/digest/digest_package_api/digest_package_funcs.html>
- <https://cj-docs.gitcode.com/zh/1.2.0/libs/std/core/core_samples/core_cstring_sample.html>

**官方源码仓（raw Markdown，本文引文的主要来源）**

- `Cangjie/cangjie_docs` → <https://raw.gitcode.com/Cangjie/cangjie_docs/raw/main/README_zh.md>、`docs/dev-guide/source_zh_cn/**`、`docs/tools/source_zh_cn/cmd-tools/**`
- `Cangjie/cangjie_stdx` → <https://raw.gitcode.com/Cangjie/cangjie_stdx/raw/main/README_zh.md>、`doc/libs_stdx/**`（`encoding/json`、`encoding/json_stream`、`net/http`、`net/tls`、`crypto/digest`、`serialization`、`log/logger`）
- `Cangjie/cangjie_runtime` → `stdlib/doc/libs/std/crypto/digest/**`（std 侧 `Digest` 接口与 `digest` 函数）
- `Cangjie/cangjie_build` → <https://raw.gitcode.com/Cangjie/cangjie_build/raw/main/docs/linux_ohos_toolchain.md>、`docs/macos_ohos.md`（OHOS 工具链构建）
- `Cangjie/cangjie_multiplatform_interop` → <https://raw.gitcode.com/Cangjie/cangjie_multiplatform_interop/raw/main/README.md>（Java/ObjC 互操作，**不是** ArkTS）
- 组织与仓库索引：<https://gitcode.com/Cangjie>（含 `cangjie_compiler` / `cangjie_runtime` / `cangjie_stdx` / `cangjie_tools` / `cangjie_docs` / `cangjie_test` / `cangjie_multiplatform_interop` / `cangjie_build` 等）
- 中心仓：<https://pkg.cangjie-lang.cn/index>；社区库：<https://gitcode.com/Cangjie-TPC>

**未能取证**

- <https://developer.huawei.com/consumer/cn/cangjie/>（华为开发者联盟仓颉分册，客户端渲染，抓取无正文）
