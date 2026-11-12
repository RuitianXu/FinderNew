# FinderNew

macOS 上的 Finder「新建文件」工具 —— 在 Finder 右键菜单中提供 Windows 风格的「新建」入口，支持 txt / md / py 等文本模板与自定义完整文件模板。

> 🚧 开发中：当前为 Phase 0 Spike（右键菜单 → 创建文本文件已验证可用），模板管理与 Office 模板在 Phase 1 实现。

## 功能（规划）

- Finder 右键 + 工具栏双入口，新建常用格式文件
- 内置合法空白 Office 文档模板（docx / pptx / xlsx）
- 自定义模板：文本初始内容 或 任意现有文件作为模板
- 模板启用/停用、排序，中英文界面
- 独占创建（`O_EXCL` 语义），绝不覆盖已有文件

## 系统要求

- macOS 13 Ventura 或更高版本
- Apple Silicon（Intel 支持待验证）

## 安装（开发构建，未公证）

```bash
git clone https://github.com/<your-account>/FinderNew.git
cd FinderNew
Scripts/build.sh
cp -R build/FinderNew.app /Applications/
open /Applications/FinderNew.app
```

首次使用需在「系统设置 → 通用 → 登录项与扩展 → Finder 扩展」中启用 **FinderNew**。

## 已知限制

- iCloud Drive / File Provider 云同步目录可能不显示第三方右键菜单（系统限制）
- 开发构建为 ad-hoc 签名、未公证，首次打开需右键 → 打开

## 许可证

[MIT](LICENSE)
