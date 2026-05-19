#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 3 ]; then
  echo "usage: $0 <version> <fonts-dir> <release-dir>" >&2
  exit 2
fi

version="$1"
fonts_dir="$2"
release_dir="$3"

styles=(Regular Medium Italic MediumItalic Bold BoldItalic)
variants=(SC TC)

mkdir -p "$release_dir"

for variant in "${variants[@]}"; do
  required_fonts=()
  for style in "${styles[@]}"; do
    required_fonts+=("JetBrainsSarasaMonoNerd${variant}-${style}.ttf")
  done

  for font in "${required_fonts[@]}"; do
    if [ ! -f "$fonts_dir/$font" ]; then
      echo "Missing built font: $fonts_dir/$font" >&2
      exit 1
    fi
    cp "$fonts_dir/$font" "$release_dir/$font"
  done

  archive="JetBrainsSarasaMonoNerd${variant}-${version}.zip"
  (
    cd "$release_dir"
    zip -q "$archive" "${required_fonts[@]}"
  )
done

for variant in "${variants[@]}"; do
  for style in "${styles[@]}"; do
    printf '%s\n' "$release_dir/JetBrainsSarasaMonoNerd${variant}-${style}.ttf"
  done
  printf '%s\n' "$release_dir/JetBrainsSarasaMonoNerd${variant}-${version}.zip"
done
