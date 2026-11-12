# FinderNew 调研与实施计划

- 日期：2026-11-12
- 状态：调研完成，产品决策已确认，等待按本计划实施
- 项目定位：开源 macOS Finder 新建文件工具，以“任意文件都能成为模板”为差异化核心

## 1. 背景与目标

macOS Finder 默认没有 Windows 风格的“右键 → 新建”入口。FinderNew 的目标是在 Finder 中提供原生、轻量、可扩展的新建文件体验，并支持通过 GitHub Releases 分发适用于 Mac 的安装包。

### 初版目标

1. 在 Finder 文件夹空白处、文件或文件夹右键菜单中提供“New File / 新建文件”子菜单。
2. 支持 `docx`、`pptx`、`xlsx`、`txt`、`md`、`py`、`json`、`yaml`、`csv`、`html` 等常用格式。
3. 内置合法空白 Office 文档，而不是仅修改空文件扩展名。
4. 支持两类自定义模板：
   - 文本模板：菜单名、默认文件名、扩展名、UTF-8 初始内容。
   - 完整文件模板：复制用户选择的任意文件，包括 Office、iWork 及其他二进制格式。
5. 支持模板添加、编辑、删除、启用/停用、拖动排序，以及中英文界面。
6. 自动避让重名，禁止覆盖现有文件；创建成功后选中新文件。
7. 提供 Finder 工具栏入口，作为部分云同步目录中右键不可用时的补充。
8. 建立开源仓库、版本发布和后续自动更新所需的基础工程结构。

### 非目标

- 初版不做综合右键工具箱，不加入压缩、OCR、批量重命名等无关功能。
- 初版不以上架 Mac App Store 为目标，采用 GitHub Releases 分发。
- 不通过 AppleScript `do shell script` 绕过沙盒，不要求辅助功能或输入监控权限。
- 不承诺第三方 Finder Sync 右键菜单在 iCloud Drive 或所有 File Provider 云盘目录中可用。
- 新建 `.py` 文件不包含 Python 解释器，也不负责运行脚本。

## 2. GitHub 竞品调研

以下数据为 2026-11-12 查询结果，star 为当时量级，不代表长期数据。

### 2.1 直接竞品

| 项目 | 核心能力 | 技术与模板方式 | 许可证 / 状态 | 对 FinderNew 的启示 |
|---|---|---|---|---|
| [Finder Menu](https://github.com/nikgrbn/finder-menu) | 新建任意名称文件、终端、路径操作；约 549 stars | Swift Finder Sync；沙盒扩展 + 非沙盒宿主；保存的是“文件名模板” | MIT；v1.5.6，2026-10-16；Homebrew/源码安装 | 最小权限架构的重要参考；需设计安全 IPC，而非开放任意命令入口 |
| [NewFile](https://github.com/mariusgm/newfile) | 自定义类型、文本初始内容、排序、工具栏入口；约 82 stars | Swift/SwiftUI Finder Sync；文本模板；扩展内写文件 | MIT；v0.2.4，2026-10-07；DMG/Homebrew | 设置体验和工具栏回退值得参考；任意扩展名不等于有效 Office 文件 |
| [MacNewFile](https://github.com/GarfieldFluffJr/MacNewFile) | DOCX/XLSX/PPTX、Pages/Numbers/Keynote；约 207 stars | Objective-C Finder Sync；Office ZIP/XML 与 iWork 空白模板 | GPL-3.0；v3.1.1，2026-04-14；DMG/Homebrew | 证明 Office/iWork 新建需求真实存在；FinderNew 应采用统一的完整文件模板机制 |
| [GOGOGTA/NewFileMenu](https://github.com/GOGOGTA/NewFileMenu) | Windows 风格 Office/Markdown 新建；约 2 stars | Swift Finder Sync；内置真实 Office 模板 | 未声明许可证；v1.1.0，2026-07-17 | 可参考产品行为，不直接复制无许可代码或模板资源 |
| [Super RClick](https://github.com/CalvinQin/SuperRClick) | 18 种格式及综合右键功能；约 10 stars | Swift 6/SwiftUI Finder Sync | MIT；v0.3.0-beta.1，2026-10-24 | 功能全面但范围较大；FinderNew 初版保持专注 |
| [MacNewFileKit](https://github.com/ywu73/MacNewFileKit) | 常用格式、文本模板、独占文件创建 | Swift 分层；`open(2)` + `O_CREAT | O_EXCL` | 未声明许可证；无 Release | 原子、禁止覆盖的创建方式值得独立实现与测试 |
| [Empty New File](https://github.com/ololx/empty-new-file) | 可配置扩展名的空文件；约 27 stars | 早期 Swift Finder Sync | MIT；Alpha 包停留在 2021 年 | 简单方案已不足以覆盖有效 Office 文档及模板管理 |

### 2.2 其他相关项目

- [hehaoqi/new-file-menu](https://github.com/hehaoqi/new-file-menu)：MIT，内置 Office 模板，使用 Finder Sync + URL Scheme；公开构建仅 ARM64、macOS 14+。
- [tungping/NewFileMenu](https://github.com/tungping/NewFileMenu)：GPL-3.0，支持默认文本内容与 `/Volumes`，无 Release。
- [cnsworder/macnewfile](https://github.com/cnsworder/macnewfile)：早期任意模板文件思路，长期停更且许可证表述不规范。
- [Alfred New File](https://github.com/x-o-r-r-o/alfred-new-file)：支持任意现有文件作为模板及占位符，但依赖 Alfred，不是 Finder 原生右键。
- [OpenInTerminal](https://github.com/Ji4n1ng/OpenInTerminal)：成熟 Finder 集成项目，可借鉴设置、签名与兼容策略，但不是新建文件工具。
- [MacOS File Summoner](https://github.com/bjesuiter/macos-file-summoner)：工具栏 + AppleScript 路径获取方案；不是原生右键，且需要额外自动化授权。

### 2.3 调研结论与差异化

现有工具通常只覆盖以下一种模板概念：

1. 只保存文件名，如 Finder Menu。
2. 保存文本初始内容，如 NewFile。
3. 固定内置 Office 模板，如 MacNewFile。

**FinderNew 将统一“文本模板”和“完整文件模板”，让用户能把现有文档直接加入模板库。** 初版聚焦新建文件，不与综合右键工具箱比拼功能数量。

## 3. 已确认的产品决策

1. **模板系统优先**：初版即包含常用格式、自定义文本/完整文件模板、排序及中英文界面。
2. **最小权限优先**：优先验证“沙盒 Finder Sync 扩展 + 非沙盒宿主”的写入架构，不使用宽泛临时文件访问例外作为默认方案。
3. **预留正式发布**：个人版本可先本地签名；工程预留 Developer ID、Hardened Runtime、公证及 GitHub Release 自动化，待有证书后启用。
4. **先建个人仓库**：使用用户个人 GitHub 账号下的新仓库；公开前检查许可证、模板资源来源、签名信息与文档。

## 4. 技术方案

### 4.1 技术栈与兼容目标

- Swift，宿主设置界面使用 SwiftUI，Finder 菜单使用 AppKit `NSMenu`。
- 普通 macOS App 内嵌 Finder Sync Extension（`.appex`）。
- 最低系统版本暂定 macOS 13 Ventura；以实际构建和真机测试为准。
- 首发源码同时支持 arm64 与 x86_64；公开包目标为 Universal 2。
- 包标识采用反向 DNS 形式，正式仓库建立后统一确定，不在扩展与宿主间混用。

### 4.2 组件划分

```text
FinderNew.app
├── Host App（非沙盒，负责设置、模板库、文件创建）
├── Finder Sync Extension（沙盒，负责菜单与获取 Finder 上下文）
└── Shared Core（模板模型、命名规则、错误模型、通信协议）
```

职责约束：

- 扩展只负责构造菜单，并在菜单回调期间读取 `targetedURL()` 和必要的 `selectedItemURLs()`。
- 宿主负责读取模板、校验目标路径、创建文件和选中新文件。
- Shared Core 不依赖 Finder 私有 API。
- 不把 shell 命令、可执行路径或任意动作作为 IPC 输入。

### 4.3 IPC 方案：先 spike，再冻结设计

首选评估 XPC；若宿主未被常规启动或扩展到宿主的 XPC 连接受限，再评估经过严格校验的自定义 URL Scheme。第一阶段必须验证：

1. 扩展启用而宿主未运行时，能否可靠唤起宿主并完成创建。
2. 通信能否校验双方代码签名、Team ID 和 bundle 身份。
3. 模板标识、目标路径和请求 ID 是否能安全编码，避免路径穿越、URL 注入及重放。
4. 创建结果和可读错误如何返回给用户。
5. 多次快速点击是否产生重复请求；采用请求 ID 做幂等处理。

只有 spike 通过后才确定最终 IPC。若使用 URL Scheme，仅允许固定 `create` 动作、模板 UUID 和目标目录 URL；宿主要求签名验证，不接收任意命令。

### 4.4 Finder 菜单与路径规则

实现：

- `menu(for: .contextualMenuForContainer)`：当前文件夹。
- `menu(for: .contextualMenuForItems)`：右键单个文件夹时在该文件夹内创建；右键文件时在其父目录创建；多选时初版禁用新建或采用明确的一致规则。
- `menu(for: .toolbarItemMenu)`：工具栏下拉入口。
- 目标 URL 只在菜单构造/action 回调中读取，不全局缓存“当前 Finder 目录”。
- 目录监控覆盖根目录及已挂载卷，并处理卷挂载/卸载；实测外置磁盘和 SMB。

### 4.5 模板与文件创建

模板元数据建议包含：

```text
id: UUID
displayName: 本地化可编辑名称
defaultBaseName: 默认主文件名
fileExtension: 规范化扩展名
kind: text | file
textContent: 文本模板内容（text）
storedTemplateFilename: App 容器内的副本（file）
isEnabled: Bool
sortOrder: Int
```

规则：

- 内置 Office 模板来自自行生成且已验证的合法 OOXML 文件；不复制无许可项目资源。
- 用户导入完整文件模板时复制到宿主 App 容器，避免原文件移动后失效。
- 初版不做文本变量替换；占位符作为后续可选功能，避免不同文件格式转义复杂化。
- 文件名清理 `/`、NUL、非法路径组件；允许 `.env`、`.gitignore` 等 dotfile 模板。
- 使用 `Untitled.docx`、`Untitled 2.docx` 等唯一命名，具体可本地化为“未命名”。
- 以独占创建保证“不覆盖”，避免先检查再写入的竞态。
- 完整模板复制采用同目录临时文件 + 原子发布；失败时清理临时文件。
- 完成后调用 `NSWorkspace.activateFileViewerSelecting` 选中新文件。

### 4.6 用户界面

宿主 App 初版包含：

1. **模板列表**：启用状态、类型、默认文件名、排序、编辑、删除。
2. **模板编辑器**：文本/文件模板二选一；导入现有文件；校验扩展名和默认文件名。
3. **通用设置**：语言跟随系统/中文/英文，创建后选中，启动登录项（可选）。
4. **安装帮助**：启用 Finder 扩展、添加工具栏按钮、权限和云盘限制说明。
5. **诊断页**：扩展状态、宿主版本、最近错误、日志导出；不记录模板内容或完整私人路径。

### 4.7 已知平台限制

- Finder Sync 是公开 API，但最初面向同步状态，不是完整 Finder UI 扩展框架。
- iCloud Drive、桌面与文稿同步及其他 File Provider 目录可能不显示第三方右键菜单。
- 工具栏入口在部分云盘场景可回退，但不保证覆盖所有目录；必须实测并如实写明。
- 用户通常需要启动宿主一次，并在“系统设置 → 通用 → 登录项与扩展”启用扩展；工具栏按钮需手动拖入。
- 本地/ad-hoc 签名适合开发，不等于可供普通用户无障碍安装的公开版本。

参考资料：

- [Apple Finder Sync 指南](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/Finder.html)
- [FIFinderSync API](https://developer.apple.com/documentation/findersync/fifindersync)
- [Apple Universal Binary 指南](https://developer.apple.com/documentation/apple-silicon/building-a-universal-macos-binary)
- [Apple 公证指南](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution)

## 5. 实施阶段与验收标准

### Phase 0：仓库与技术验证

- 初始化个人 GitHub 仓库、`.gitignore`、MIT License、README、基础目录。
- 建立 Xcode 宿主 + 扩展 + Shared Core 工程。
- 完成扩展菜单、宿主唤起、双向身份校验、文件写入 spike。
- 测试普通目录、桌面、外置卷及 iCloud/File Provider 行为。

**通过条件**：从一个真实 Finder 右键动作创建文本文件，未要求 Accessibility，无任意命令 IPC；明确记录不支持的场景。

### Phase 1：模板与核心文件创建

- 实现模板模型、持久化、导入副本及内置常用格式。
- 生成并验证空白 DOCX/PPTX/XLSX；文本模板使用 UTF-8。
- 实现独占创建、唯一命名、失败清理、选中新文件。
- 建立单元测试：命名、dotfile、Unicode、重名、并发、非法名称、禁止覆盖。

**通过条件**：Office 文件可由对应应用或标准 OOXML 校验工具打开；并发创建不覆盖、不破坏已有文件。

### Phase 2：完整右键与设置体验

- 完成右键子菜单、工具栏菜单、模板增删改排和中英文。
- 完成安装帮助、空状态、错误提示、诊断信息。
- 检查无宿主运行、宿主升级、扩展重载、多窗口、多标签等状态。

**通过条件**：用户仅依据 README 和 App 引导即可启用扩展并创建/导入模板。

### Phase 3：兼容性与质量

- 测试 Apple Silicon；条件具备时测试 Intel 或 Universal 构建产物。
- 覆盖 macOS 13 至当前可用版本的代表性环境。
- 测试本地目录、桌面、外置磁盘、SMB；分别记录云盘右键和工具栏结果。
- 检查断点/异常退出、磁盘已满、无权限、只读卷、模板丢失等错误路径。
- 使用 Crash-free 体验和日志诊断，不加入未经说明的数据采集。

**通过条件**：支持矩阵写入 README，不将未测试环境标为已支持。

### Phase 4：开源与发布工程

- 补齐 README 中英文、截图、安装/卸载、权限、安全、故障排除和贡献指南。
- 所有第三方依赖与资源列明许可证；无许可竞品仅作行为参考。
- GitHub Actions 执行构建、测试、产物架构及签名检查。
- 个人版本可上传明确标注“未公证”的开发构建，但不作为普通用户正式安装包。
- 正式 Release 使用 Developer ID Application、Hardened Runtime、DMG、公证和 stapling。
- 证书、私钥、Keychain 与 notary 凭证只放 GitHub Secrets。
- 验证 quarantine 下首次启动、扩展启用、升级与卸载。
- 后续版本可评估 Sparkle 自动更新；初版先保证 GitHub Release 检查更新，不在未验证前引入额外依赖。

**通过条件**：干净测试用户环境可下载安装并通过 Gatekeeper；`spctl`、`stapler validate`、宿主和扩展 `lipo -info` 检查通过。

## 6. 测试矩阵

| 类别 | 必测场景 |
|---|---|
| 文件格式 | TXT/MD/PY/JSON/YAML/CSV/HTML；DOCX/PPTX/XLSX；用户二进制模板 |
| 文件名 | 中文、emoji、空格、dotfile、长名称、重复名称、非法字符 |
| 安全性 | 不覆盖、路径穿越、伪造 IPC、模板 UUID 不存在、重复请求、符号链接边界 |
| Finder | 空白处、文件、文件夹、多选、工具栏、多窗口、多标签 |
| 存储 | 主目录、其他本地目录、外置卷、SMB、只读卷、云同步目录 |
| 系统状态 | 宿主未运行、扩展重载、升级、磁盘已满、无写权限 |
| 本地化 | 中文、英文、跟随系统；菜单与错误信息无缺失 |

## 7. GitHub 与版本策略

- 仓库名暂定 `FinderNew`，公开前确认名称及 bundle ID 可用性。
- 使用 MIT License；如引入依赖，单独审查其许可证兼容性。
- `main` 保持稳定；功能分支 + Pull Request，即使个人开发也保留变更记录。
- 语义化版本：`0.1.0` 为首个公开 MVP，修复/功能/破坏性变化分别升级对应位。
- GitHub Actions 分两类：普通 PR 测试（无签名秘密）与 tag 发布（签名、公证、Release）。
- Release 包含 Universal DMG、SHA-256、更新日志、系统要求、签名/公证状态和已知限制。
- 不在仓库提交证书、 provisioning 私有信息、notary 凭证、用户模板或隐私日志。

## 8. 风险与应对

| 风险 | 应对 |
|---|---|
| 扩展到宿主的 IPC 或身份校验比预期复杂 | Phase 0 先做最小 spike；XPC 与 URL Scheme 只保留一种通过验证的方案 |
| 云盘目录没有第三方右键 | 明示系统限制；提供工具栏入口，记录实测支持矩阵，不使用私有 Finder 注入 |
| 非沙盒宿主攻击面扩大 | 固定动作、模板 UUID、严格路径校验、调用者签名校验、请求幂等；不执行脚本 |
| Office 模板包含私人元数据或无效结构 | 自行生成、清理元数据、自动校验 ZIP/OOXML，并用 Office/LibreOffice 实测 |
| Universal 构建只有宿主是双架构 | 分别检查宿主、扩展和依赖 Mach-O |
| 个人开发包被误认为正式公证包 | Release 明确标记开发/正式状态；正式分发只在公证通过后进行 |
| 无许可竞品代码或资源被误用 | 独立实现；只参考公开行为和有许可架构，保留资源来源清单 |

## 9. 首个里程碑交付物

1. 可运行的 FinderNew 宿主 App 与 Finder Sync Extension。
2. 常用格式 + 自定义文本/完整文件模板 + 模板管理。
3. 中英文 README、安装帮助和已知平台限制。
4. 单元测试、核心集成测试和兼容性记录。
5. 个人 GitHub 仓库及可复现构建说明。
6. 预留的签名、公证、Universal DMG 与 GitHub Release 流水线。

本计划仅定义实施路径；尚未创建应用、仓库或发布安装包。
