#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
usage: scripts/fetch-upstream-fonts.sh <output-dir> <work-dir> [nerd-fonts-url] [sarasa-mono-url]

Downloads and prepares source fonts for local and CI builds.
When URLs are omitted, the script resolves the latest GitHub release assets.
EOF
}

if [ "$#" -ne 2 ] && [ "$#" -ne 4 ]; then
  usage
  exit 2
fi

output_dir="$1"
work_dir="$2"
nerd_url="${3:-}"
sarasa_url="${4:-}"

require_value() {
  local name="$1"
  local value="$2"

  if [ -z "$value" ] || [ "$value" = "null" ]; then
    echo "ERROR: $name is required" >&2
    exit 1
  fi
}

require_command() {
  local command_name="$1"

  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "ERROR: $command_name is required" >&2
    exit 1
  fi
}

require_value "output directory" "$output_dir"
require_value "work directory" "$work_dir"

require_command curl
require_command unzip

mkdir -p "$output_dir" "$work_dir"

python_bin="${PYTHON:-}"
if [ -z "$python_bin" ]; then
  if command -v python3 >/dev/null 2>&1; then
    python_bin="python3"
  elif command -v python >/dev/null 2>&1; then
    python_bin="python"
  elif [ -x ".venv/bin/python" ]; then
    python_bin=".venv/bin/python"
  else
    echo "ERROR: python3 or python is required" >&2
    exit 1
  fi
fi

resolve_latest_url() {
  local repo="$1"
  local selector="$2"

  "$python_bin" - "$repo" "$selector" <<'PY'
import json
import re
import sys
import urllib.request

repo = sys.argv[1]
selector = sys.argv[2]
url = f"https://api.github.com/repos/{repo}/releases/latest"
request = urllib.request.Request(url, headers={"User-Agent": "jetbrains-sarasa-mono-nerd-builder"})
with urllib.request.urlopen(request) as response:
    release = json.load(response)

for asset in release["assets"]:
    name = asset["name"]
    lower = name.lower()
    normalized = re.sub(r"[^a-z0-9]", "", lower)
    if selector == "nerd" and name == "JetBrainsMono.zip":
        print(asset["browser_download_url"])
        break
    if (
        selector == "sarasa"
        and lower.endswith(".zip")
        and "sarasamono" in normalized
        and "ttf" in normalized
        and "unhinted" not in lower
    ):
        print(asset["browser_download_url"])
        break
else:
    raise SystemExit(f"Unable to resolve {selector} asset for {repo}")
PY
}

if [ -z "$nerd_url" ]; then
  nerd_url="$(resolve_latest_url "ryanoasis/nerd-fonts" "nerd")"
fi
if [ -z "$sarasa_url" ]; then
  sarasa_url="$(resolve_latest_url "be5invis/Sarasa-Gothic" "sarasa")"
fi

require_value "Nerd Fonts download URL" "$nerd_url"
require_value "Sarasa Mono download URL" "$sarasa_url"

nerd_archive="$work_dir/JetBrainsMono.zip"
sarasa_archive="$work_dir/SarasaMono.zip"
nerd_extract="$work_dir/JetBrainsMono"
sarasa_extract="$work_dir/SarasaMono"

download_archive() {
  local label="$1"
  local url="$2"
  local output="$3"

  echo "Downloading $label..."
  curl -fL --retry 3 --retry-delay 5 "$url" -o "$output"
}

download_archive "Nerd Fonts" "$nerd_url" "$nerd_archive" &
pid_nerd=$!
download_archive "Sarasa Mono" "$sarasa_url" "$sarasa_archive" &
pid_sarasa=$!

download_failed=false
if ! wait "$pid_nerd"; then
  echo "ERROR: failed to download Nerd Fonts archive: $nerd_url" >&2
  download_failed=true
fi
if ! wait "$pid_sarasa"; then
  echo "ERROR: failed to download Sarasa Mono archive: $sarasa_url" >&2
  download_failed=true
fi
if [ "$download_failed" = "true" ]; then
  exit 1
fi

rm -rf "$nerd_extract" "$sarasa_extract"
unzip -q "$nerd_archive" -d "$nerd_extract"
unzip -q "$sarasa_archive" -d "$sarasa_extract"

copy_exact_font() {
  local root="$1"
  local name="$2"
  local source

  if ! source="$(
    "$python_bin" - "$root" "$name" <<'PY'
from pathlib import Path
import sys

root = Path(sys.argv[1])
name = sys.argv[2]

for path in root.rglob(name):
    if path.is_file():
        print(path)
        break
else:
    raise SystemExit(1)
PY
  )"; then
    echo "Missing font file: $name" >&2
    exit 1
  fi

  cp "$source" "$output_dir/$name"
}

copy_normalized_font() {
  local root="$1"
  local target="$2"
  local source

  if ! source="$(
    "$python_bin" - "$root" "$target" <<'PY'
from pathlib import Path
import re
import sys

root = Path(sys.argv[1])
target = sys.argv[2]
target_key = re.sub(r"[^a-z0-9]", "", target.lower())

for path in root.rglob("*.ttf"):
    key = re.sub(r"[^a-z0-9]", "", path.name.lower())
    if key == target_key:
        print(path)
        break
else:
    raise SystemExit(1)
PY
  )"; then
    echo "Missing Sarasa font file matching: $target" >&2
    exit 1
  fi

  cp "$source" "$output_dir/$target"
}

copy_exact_font "$nerd_extract" "JetBrainsMonoNLNerdFontMono-Regular.ttf"
copy_exact_font "$nerd_extract" "JetBrainsMonoNLNerdFontMono-Medium.ttf"
copy_exact_font "$nerd_extract" "JetBrainsMonoNLNerdFontMono-Italic.ttf"
copy_exact_font "$nerd_extract" "JetBrainsMonoNLNerdFontMono-MediumItalic.ttf"
copy_exact_font "$nerd_extract" "JetBrainsMonoNLNerdFontMono-Bold.ttf"
copy_exact_font "$nerd_extract" "JetBrainsMonoNLNerdFontMono-BoldItalic.ttf"

for locale in SC TC; do
  copy_normalized_font "$sarasa_extract" "SarasaMono${locale}-Regular.ttf"
  copy_normalized_font "$sarasa_extract" "SarasaMono${locale}-SemiBold.ttf"
  copy_normalized_font "$sarasa_extract" "SarasaMono${locale}-Italic.ttf"
  copy_normalized_font "$sarasa_extract" "SarasaMono${locale}-SemiBoldItalic.ttf"
  copy_normalized_font "$sarasa_extract" "SarasaMono${locale}-Bold.ttf"
  copy_normalized_font "$sarasa_extract" "SarasaMono${locale}-BoldItalic.ttf"
done

echo "Prepared source fonts in $output_dir"
