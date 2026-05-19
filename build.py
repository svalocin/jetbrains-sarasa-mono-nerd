#!/usr/bin/env python3
"""
JetBrains Sarasa Mono Nerd font builder.

Build merged fonts with:
- English characters from JetBrainsMono Nerd Font
- CJK characters from Sarasa Mono SC/TC
- Nerd Font icons preserved
- 2:1 width ratio (CJK 1200, English 600)
"""

import argparse
import json
import sys
from concurrent.futures import ProcessPoolExecutor, as_completed
from pathlib import Path
from typing import Any, Dict, List

import yaml

sys.path.insert(0, str(Path(__file__).parent))

from src.config import FontConfig
from src.merge import center_cjk_glyphs, merge_fonts, scale_nerd_icons
from src.utils import update_font_names, verify_glyph_width


def load_config(config_path: Path) -> Dict[str, Any]:
    if not config_path.exists():
        return {}

    with open(config_path, "r", encoding="utf-8") as f:
        return yaml.safe_load(f) or {}


def get_config_value(yaml_config: Dict[str, Any], *keys: str, default: Any = None) -> Any:
    value = yaml_config
    for key in keys:
        if not isinstance(value, dict):
            return default
        value = value.get(key)
        if value is None:
            return default
    return value


def build_single_font(
    variant_key: str,
    style: str,
    en_font_path: Path,
    cn_font_path: Path,
    display_name: str,
    output_dir: Path,
    config: FontConfig,
    metadata: dict,
) -> str:
    print(f"\nBuilding {config.family_name_compact}-{style} ({variant_key})...")

    merged_font = merge_fonts(
        base_font_path=str(en_font_path),
        cn_font_path=str(cn_font_path),
        config=config,
    )

    print("  Scaling NerdFont icons...")
    scale_nerd_icons(merged_font, config)

    print("  Centering CJK glyphs...")
    center_cjk_glyphs(merged_font, config)

    postscript_name = f"{config.family_name_compact}-{style}"

    print("  Updating font metadata...")
    update_font_names(
        font=merged_font,
        family_name=config.family_name,
        style_name=display_name,
        full_name=f"{config.family_name} {display_name}",
        postscript_name=postscript_name,
        version_str=f"Version {config.version}",
        author=metadata.get("author", ""),
        copyright_str=metadata.get("copyright", ""),
        description=metadata.get("description", ""),
        url=metadata.get("url", ""),
        license_desc=metadata.get("license", ""),
        license_url=metadata.get("license_url", ""),
    )

    print("  Verifying glyph widths...")
    verify_glyph_width(
        font=merged_font,
        expected_widths=[0, config.en_width, config.cn_width],
        file_name=postscript_name,
    )

    output_path = output_dir / f"{postscript_name}.ttf"
    merged_font.save(str(output_path))
    merged_font.close()

    print(f"  Saved: {output_path}")
    return str(output_path)


def resolve_font_name(template: str, variant_cfg: Dict[str, Any]) -> str:
    return template.format(**variant_cfg)


def main() -> None:
    default_config_path = Path(__file__).parent / "config.yaml"

    parser = argparse.ArgumentParser(
        description="Build JetBrains Sarasa Mono Nerd SC/TC fonts",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  uv run python build.py
  uv run python build.py --fonts-dir build/source-fonts --output-dir build/fonts --parallel 6

Configuration priority: CLI args > config.yaml > defaults
        """,
    )
    parser.add_argument(
        "--config",
        type=Path,
        default=default_config_path,
        help=f"Path to config.yaml (default: {default_config_path})",
    )
    parser.add_argument(
        "--fonts-dir",
        type=Path,
        default=None,
        help="Directory containing source fonts (default: from config or build/source-fonts/)",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=None,
        help="Output directory (default: from config or build/fonts/)",
    )
    parser.add_argument(
        "--parallel",
        type=int,
        default=None,
        help="Number of parallel workers (default: from config or 1)",
    )
    parser.add_argument(
        "--version",
        type=str,
        default=None,
        help="Override font version metadata (default: from config)",
    )

    args = parser.parse_args()
    yaml_config = load_config(args.config)

    variants_config = get_config_value(yaml_config, "variants") or {}
    styles_config = get_config_value(yaml_config, "styles") or {}
    if not variants_config:
        print("Error: No variants defined in config.yaml")
        sys.exit(1)
    if not styles_config:
        print("Error: No styles defined in config.yaml")
        sys.exit(1)

    fonts_dir = args.fonts_dir or Path(
        get_config_value(yaml_config, "fonts_dir") or "build/source-fonts"
    )
    output_dir = args.output_dir or Path(
        get_config_value(yaml_config, "build", "output_dir") or "build/fonts"
    )
    parallel = (
        args.parallel
        if args.parallel is not None
        else get_config_value(yaml_config, "build", "parallel", default=1)
    )

    version = args.version or get_config_value(yaml_config, "font", "version") or "1.0"
    en_width = get_config_value(yaml_config, "width", "en_width", default=600)
    cn_width = get_config_value(yaml_config, "width", "cn_width", default=1200)
    visual_scale = get_config_value(yaml_config, "width", "visual_scale", default=1.0)

    metadata = {
        "author": get_config_value(yaml_config, "font", "author") or "",
        "copyright": get_config_value(yaml_config, "font", "copyright") or "",
        "description": get_config_value(yaml_config, "font", "description") or "",
        "url": get_config_value(yaml_config, "font", "url") or "",
        "license": get_config_value(yaml_config, "font", "license") or "",
        "license_url": get_config_value(yaml_config, "font", "license_url") or "",
    }

    jobs: List[Dict[str, Any]] = []
    manifest = {"version": version, "variants": []}

    for variant_key, variant_cfg in variants_config.items():
        family_name = variant_cfg.get("family_name")
        family_name_compact = variant_cfg.get("family_name_compact")
        if not family_name or not family_name_compact:
            print(f"Error: Variant '{variant_key}' must define family_name and family_name_compact")
            sys.exit(1)

        variant_fonts = []
        config = FontConfig(
            family_name=family_name,
            family_name_compact=family_name_compact,
            version=version,
            visual_scale=visual_scale,
            en_width=en_width,
            cn_width=cn_width,
        )

        for style, style_cfg in styles_config.items():
            en_font = style_cfg.get("en_font")
            cn_font_template = style_cfg.get("cn_font")
            display_name = style_cfg.get("display_name", style)
            if not en_font or not cn_font_template:
                print(f"Error: Style '{style}' must define en_font and cn_font")
                sys.exit(1)

            cn_font = resolve_font_name(cn_font_template, variant_cfg)
            en_font_path = fonts_dir / en_font
            cn_font_path = fonts_dir / cn_font

            if not en_font_path.exists():
                print(f"Error: English font not found: {en_font_path}")
                sys.exit(1)
            if not cn_font_path.exists():
                print(f"Error: CJK font not found: {cn_font_path}")
                sys.exit(1)

            jobs.append(
                {
                    "variant_key": variant_key,
                    "style": style,
                    "en_font_path": en_font_path,
                    "cn_font_path": cn_font_path,
                    "display_name": display_name,
                    "output_dir": output_dir,
                    "config": config,
                    "metadata": metadata,
                }
            )
            variant_fonts.append(
                {
                    "style": style,
                    "display_name": display_name,
                    "filename": f"{family_name_compact}-{style}.ttf",
                }
            )

        manifest["variants"].append(
            {
                "key": variant_key,
                "family_name": family_name,
                "family_name_compact": family_name_compact,
                "fonts": variant_fonts,
            }
        )

    output_dir.mkdir(parents=True, exist_ok=True)

    print(f"Building JetBrains Sarasa Mono Nerd v{version}")
    print(f"Variants: {', '.join(variants_config.keys())}")
    print(f"Styles: {', '.join(styles_config.keys())}")
    print(f"Source: {fonts_dir}")
    print(f"Output: {output_dir}")
    print(f"Width ratio: {cn_width}:{en_width} (2:1)")
    print("Font mapping:")
    for job in jobs:
        print(f"  {job['config'].family_name_compact}-{job['style']}:")
        print(f"    EN: {job['en_font_path'].name}")
        print(f"    CJK: {job['cn_font_path'].name}")

    if parallel <= 1:
        for job in jobs:
            build_single_font(**job)
    else:
        with ProcessPoolExecutor(max_workers=parallel) as executor:
            futures = {executor.submit(build_single_font, **job): job for job in jobs}
            for future in as_completed(futures):
                job = futures[future]
                try:
                    future.result()
                except Exception as e:
                    print(f"Error building {job['config'].family_name_compact}-{job['style']}: {e}")
                    raise

    manifest_path = output_dir / "fonts-manifest.json"
    with open(manifest_path, "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2, ensure_ascii=False)
    print(f"Generated manifest: {manifest_path}")

    print(f"\nBuild complete! Fonts saved to: {output_dir}")


if __name__ == "__main__":
    main()
