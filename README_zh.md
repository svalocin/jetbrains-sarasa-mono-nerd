# JetBrains Sarasa Mono Nerd

中文 | [English](README.md)

JetBrains Sarasa Mono Nerd 是一套把 JetBrainsMono Nerd Font 与 Sarasa Mono CJK 字形合并而成的编程字体，目标是严格保持中英文 1:2 等宽。

本项目发布两个独立字体家族：

- `JetBrains Sarasa Mono Nerd SC`：简体中文区域字形。
- `JetBrains Sarasa Mono Nerd TC`：繁体中文区域字形。

英文、ASCII 和 Nerd Font 图标来自 JetBrainsMono Nerd Font。CJK 字形来自 Sarasa Mono 普通 hinted 包。本项目不使用 Unhinted 版本。

## 项目来源

本仓库 fork 自 [lvbibir/JetBrainsLxgwNerdMono](https://github.com/lvbibir/JetBrainsLxgwNerdMono)。

本仓库也合并了 [sspig0127](https://github.com/sspig0127) 的 pull request [lvbibir/JetBrainsLxgwNerdMono#1](https://github.com/lvbibir/JetBrainsLxgwNerdMono/pull/1)。在此基础上，本项目将 CJK 源字体替换为 Sarasa Mono SC/TC，并围绕新的字体家族重写构建和发布流程。

## 特性

- 严格 2:1 字宽比例：英文 `600`，CJK `1200`。
- Nerd Font 图标扩展到与中文等宽。
- Powerline 符号保留原始垂直边界，保证终端对齐。
- 每个 locale 提供 6 个样式：`Regular`、`Medium`、`Italic`、`MediumItalic`、`Bold`、`BoldItalic`。
- SC 和 TC 是两个独立 family，可以只安装其中一个，也可以同时安装。
- 本地构建和 CI 使用同一个上游字体准备脚本。

## 安装

### Homebrew

安装 SC：

```bash
brew tap svalocin/fonts
brew install --cask font-jetbrains-sarasa-mono-nerd-sc
```

安装 TC：

```bash
brew tap svalocin/fonts
brew install --cask font-jetbrains-sarasa-mono-nerd-tc
```

按需安装 SC、TC，或两个都安装。

### 手动安装

从 GitHub Releases 下载：

- `JetBrainsSarasaMonoNerdSC-<version>.zip`：包含 6 个 SC TTF。
- `JetBrainsSarasaMonoNerdTC-<version>.zip`：包含 6 个 TC TTF。
- 每个 Release 也会附带单独的 TTF 文件。

安装后，在编辑器或终端中选择 `JetBrains Sarasa Mono Nerd SC` 或 `JetBrains Sarasa Mono Nerd TC`。

## 字体映射

| 输出样式 | JetBrainsMono Nerd 来源 | Sarasa SC CJK 来源 | Sarasa TC CJK 来源 |
| --- | --- | --- | --- |
| `Regular` | `JetBrainsMonoNLNerdFontMono-Regular.ttf` | `SarasaMonoSC-Regular.ttf` | `SarasaMonoTC-Regular.ttf` |
| `Medium` | `JetBrainsMonoNLNerdFontMono-Medium.ttf` | `SarasaMonoSC-SemiBold.ttf` | `SarasaMonoTC-SemiBold.ttf` |
| `Italic` | `JetBrainsMonoNLNerdFontMono-Italic.ttf` | `SarasaMonoSC-Italic.ttf` | `SarasaMonoTC-Italic.ttf` |
| `MediumItalic` | `JetBrainsMonoNLNerdFontMono-MediumItalic.ttf` | `SarasaMonoSC-SemiBoldItalic.ttf` | `SarasaMonoTC-SemiBoldItalic.ttf` |
| `Bold` | `JetBrainsMonoNLNerdFontMono-Bold.ttf` | `SarasaMonoSC-Bold.ttf` | `SarasaMonoTC-Bold.ttf` |
| `BoldItalic` | `JetBrainsMonoNLNerdFontMono-BoldItalic.ttf` | `SarasaMonoSC-BoldItalic.ttf` | `SarasaMonoTC-BoldItalic.ttf` |

## 本地构建

安装 Python 依赖：

```bash
uv sync
```

准备源字体：

```bash
scripts/fetch-upstream-fonts.sh build/source-fonts build/cache/upstream-fonts
```

构建全部 SC 和 TC 字体：

```bash
uv run python build.py --parallel 6
```

默认会将 TTF 文件和 `fonts-manifest.json` 写入 `build/fonts/`。

覆盖字体版本元数据：

```bash
uv run python build.py --version 2026.05.18-031700 --parallel 6
```

使用其他源字体目录：

```bash
uv run python build.py --fonts-dir /path/to/fonts --output-dir build/fonts --parallel 6
```

源字体目录需要包含：

- `JetBrainsMonoNLNerdFontMono-Regular.ttf`
- `JetBrainsMonoNLNerdFontMono-Medium.ttf`
- `JetBrainsMonoNLNerdFontMono-Italic.ttf`
- `JetBrainsMonoNLNerdFontMono-MediumItalic.ttf`
- `JetBrainsMonoNLNerdFontMono-Bold.ttf`
- `JetBrainsMonoNLNerdFontMono-BoldItalic.ttf`
- `SarasaMonoSC-Regular.ttf`
- `SarasaMonoSC-SemiBold.ttf`
- `SarasaMonoSC-Italic.ttf`
- `SarasaMonoSC-SemiBoldItalic.ttf`
- `SarasaMonoSC-Bold.ttf`
- `SarasaMonoSC-BoldItalic.ttf`
- `SarasaMonoTC-Regular.ttf`
- `SarasaMonoTC-SemiBold.ttf`
- `SarasaMonoTC-Italic.ttf`
- `SarasaMonoTC-SemiBoldItalic.ttf`
- `SarasaMonoTC-Bold.ttf`
- `SarasaMonoTC-BoldItalic.ttf`

## 验证

构建脚本会强制检查 glyph advance width。任何 glyph 宽度不属于 `0`、`600`、`1200` 都会导致构建失败。

## 发布流程

主工作流是 `.github/workflows/build-release.yml`。

它检查以下上游 release：

- Nerd Fonts `JetBrainsMono.zip`
- Sarasa Gothic `SarasaMono` 普通 hinted TTF zip

任一上游变化时，CI 构建 12 个 TTF，上传单独 TTF 资产，并生成两个 zip：

- `JetBrainsSarasaMonoNerdSC-<version>.zip`
- `JetBrainsSarasaMonoNerdTC-<version>.zip`

`.github/workflows/homebrew-publish.yml` 会向 `svalocin/homebrew-fonts` 发布两个 cask。

## 致谢

本项目建立在这些开源项目之上：

- [JetBrains Mono](https://github.com/JetBrains/JetBrainsMono)：英文编程字体基础。
- [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts)：提供 JetBrainsMono Nerd Font 成品包。
- [Sarasa Gothic](https://github.com/be5invis/Sarasa-Gothic)：提供 Sarasa Mono SC 和 TC CJK 字形。
- [lvbibir/JetBrainsLxgwNerdMono](https://github.com/lvbibir/JetBrainsLxgwNerdMono)：本仓库 fork 的上游项目。
- [sspig0127](https://github.com/sspig0127)：其 pull request [lvbibir/JetBrainsLxgwNerdMono#1](https://github.com/lvbibir/JetBrainsLxgwNerdMono/pull/1) 已合并到本 fork。

## 许可证

本仓库遵循源字体和工具的对应许可证：

- JetBrains Mono: OFL-1.1
- Sarasa Gothic: OFL-1.1
- Nerd Fonts: MIT

请以各上游项目的许可证文本为准。
