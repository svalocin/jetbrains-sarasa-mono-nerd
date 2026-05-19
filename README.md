# JetBrains Sarasa Mono Nerd

[中文](README_zh.md) | English

JetBrains Sarasa Mono Nerd merges JetBrainsMono Nerd Font with Sarasa Mono CJK glyphs to create programming fonts with a strict 2:1 Latin/CJK monospace ratio.

This project publishes two independent font families:

- `JetBrains Sarasa Mono Nerd SC` for Simplified Chinese glyph forms.
- `JetBrains Sarasa Mono Nerd TC` for Traditional Chinese glyph forms.

The Latin, ASCII, and Nerd Font icons come from JetBrainsMono Nerd Font. CJK glyphs come from the regular hinted Sarasa Mono package. Unhinted Sarasa assets are not used.

## Project Origin

This repository is forked from [lvbibir/JetBrainsLxgwNerdMono](https://github.com/lvbibir/JetBrainsLxgwNerdMono).

It also includes the work from [sspig0127](https://github.com/sspig0127)'s pull request [lvbibir/JetBrainsLxgwNerdMono#1](https://github.com/lvbibir/JetBrainsLxgwNerdMono/pull/1). This project then replaces the LXGW CJK source fonts with Sarasa Mono SC/TC and extends the release automation around the new font families.

## Features

- Strict 2:1 width ratio: Latin glyphs use `600`, CJK glyphs use `1200`.
- Nerd Font icons are widened to match CJK width.
- Powerline symbols keep their vertical bounds for terminal alignment.
- Six styles for each locale: `Regular`, `Medium`, `Italic`, `MediumItalic`, `Bold`, `BoldItalic`.
- Separate SC and TC families, so users can install either or both.
- Local and CI builds use the same upstream font preparation script.

## Installation

### Homebrew

Install SC:

```bash
brew tap svalocin/fonts
brew install --cask font-jetbrains-sarasa-mono-nerd-sc
```

Install TC:

```bash
brew tap svalocin/fonts
brew install --cask font-jetbrains-sarasa-mono-nerd-tc
```

Install only the locale you need, or install both casks.

### Manual

Download from GitHub Releases:

- `JetBrainsSarasaMonoNerdSC-<version>.zip`: six SC TTF files.
- `JetBrainsSarasaMonoNerdTC-<version>.zip`: six TC TTF files.
- Individual TTF files are also attached to each release.

After installation, select `JetBrains Sarasa Mono Nerd SC` or `JetBrains Sarasa Mono Nerd TC` in your editor or terminal.

## Font Mapping

| Output style | JetBrainsMono Nerd source | Sarasa SC CJK source | Sarasa TC CJK source |
| --- | --- | --- | --- |
| `Regular` | `JetBrainsMonoNLNerdFontMono-Regular.ttf` | `SarasaMonoSC-Regular.ttf` | `SarasaMonoTC-Regular.ttf` |
| `Medium` | `JetBrainsMonoNLNerdFontMono-Medium.ttf` | `SarasaMonoSC-SemiBold.ttf` | `SarasaMonoTC-SemiBold.ttf` |
| `Italic` | `JetBrainsMonoNLNerdFontMono-Italic.ttf` | `SarasaMonoSC-Italic.ttf` | `SarasaMonoTC-Italic.ttf` |
| `MediumItalic` | `JetBrainsMonoNLNerdFontMono-MediumItalic.ttf` | `SarasaMonoSC-SemiBoldItalic.ttf` | `SarasaMonoTC-SemiBoldItalic.ttf` |
| `Bold` | `JetBrainsMonoNLNerdFontMono-Bold.ttf` | `SarasaMonoSC-Bold.ttf` | `SarasaMonoTC-Bold.ttf` |
| `BoldItalic` | `JetBrainsMonoNLNerdFontMono-BoldItalic.ttf` | `SarasaMonoSC-BoldItalic.ttf` | `SarasaMonoTC-BoldItalic.ttf` |

## Local Build

Install Python dependencies:

```bash
uv sync
```

Prepare source fonts:

```bash
scripts/fetch-upstream-fonts.sh build/source-fonts build/cache/upstream-fonts
```

Build all SC and TC fonts:

```bash
uv run python build.py --parallel 6
```

Generated TTF files and `fonts-manifest.json` are written to `build/fonts/` by default.

Override the version metadata:

```bash
uv run python build.py --version 2026.05.18-031700 --parallel 6
```

Use another source font directory:

```bash
uv run python build.py --fonts-dir /path/to/fonts --output-dir build/fonts --parallel 6
```

The source font directory must contain:

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

## Verification

The build fails if any glyph advance width is outside `0`, `600`, or `1200`.

## Release Workflow

The main workflow is `.github/workflows/build-release.yml`.

It checks upstream releases for:

- Nerd Fonts `JetBrainsMono.zip`
- Sarasa Gothic `SarasaMono` regular hinted TTF zip

When either upstream changes, CI builds 12 TTF files, publishes individual TTF assets, and creates two zip bundles:

- `JetBrainsSarasaMonoNerdSC-<version>.zip`
- `JetBrainsSarasaMonoNerdTC-<version>.zip`

`.github/workflows/homebrew-publish.yml` publishes two casks to `svalocin/homebrew-fonts`.

## Acknowledgements

This project exists because of the work of these upstream projects:

- [JetBrains Mono](https://github.com/JetBrains/JetBrainsMono), the Latin programming font foundation.
- [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts), which provides the patched JetBrainsMono Nerd Font package.
- [Sarasa Gothic](https://github.com/be5invis/Sarasa-Gothic), which provides the Sarasa Mono SC and TC CJK glyphs.
- [lvbibir/JetBrainsLxgwNerdMono](https://github.com/lvbibir/JetBrainsLxgwNerdMono), the upstream project this repository is forked from.
- [sspig0127](https://github.com/sspig0127), whose pull request [lvbibir/JetBrainsLxgwNerdMono#1](https://github.com/lvbibir/JetBrainsLxgwNerdMono/pull/1) is included in this fork.

## License

This repository follows the licenses of its source fonts and tools:

- JetBrains Mono: OFL-1.1
- Sarasa Gothic: OFL-1.1
- Nerd Fonts: MIT

Refer to each upstream project for authoritative license text.
