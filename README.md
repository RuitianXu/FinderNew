# FinderNew

在 macOS Finder 的右键菜单里新建文件，就像 Windows 那样。

右键空白处即可新建 txt、Markdown、Python、Word、Excel、PowerPoint 等常用文件，还能一键复制文件或文件夹路径。开机自动在后台运行，随叫随到。

## 功能

- **右键新建文件**：在文件夹空白处右键，选择格式即可创建；右键文件或文件夹时，会在对应目录里创建
- **新建 Office 文档**：内置空白的 Word / Excel / PowerPoint 模板，是真正能打开的文档，不是改扩展名的空文件。其中 Word 默认样式为中文宋体、英文 Times New Roman、字号小四、1.5 倍行距、段前段后为 0
- **复制路径**：右键空白处复制文件夹路径；右键文件复制文件路径（多选时每行一个）
- **后台常驻**：安装后自动注册为登录项，无 Dock 图标，开机即用
- **绝不覆盖**：新建时如果文件已存在，会自动命名为「未命名 2」「未命名 3」，不会覆盖你的任何文件

## 系统要求

- macOS 13 或更高版本
- Apple Silicon（M 系列）Mac

## 安装

从 [Releases](https://github.com/RuitianXu/FinderNew/releases) 下载最新的 zip 并解压：

1. 把 `FinderNew.app` 拖入「应用程序」文件夹
2. 第一次打开时右键点击 App，选择「打开」（应用未经过公证，直接双击会被拦）
3. 到「系统设置 → 通用 → 登录项与扩展 → Finder 扩展」中启用 FinderNew

之后在 Finder 里右键就能用了。

### 从源码构建

```bash
git clone https://github.com/RuitianXu/FinderNew.git
cd FinderNew
Scripts/build.sh
cp -R build/FinderNew.app /Applications/
```

构建只需要 Xcode Command Line Tools，不需要完整版 Xcode。

## 已知限制

- iCloud Drive 等云同步目录里，macOS 可能不显示第三方右键菜单，这是系统限制
- 应用使用 ad-hoc 签名，未做公证，首次打开需要右键 → 打开

## 许可证

[MIT](LICENSE)
