#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 9 ]; then
  echo "usage: $0 <token> <version> <sha256> <asset> <name> <desc> <tag> <repo> <font...>" >&2
  exit 2
fi

require_value() {
  local name="$1"
  local value="$2"

  if [ -z "$value" ] || [ "$value" = "null" ]; then
    echo "ERROR: $name is required" >&2
    exit 1
  fi
}

token="$1"
version="$2"
sha256="$3"
asset="$4"
name="$5"
desc="$6"
tag="$7"
repo="$8"
shift 8

require_value "cask token" "$token"
require_value "version" "$version"
require_value "sha256" "$sha256"
require_value "asset" "$asset"
require_value "name" "$name"
require_value "description" "$desc"
require_value "tag" "$tag"
require_value "repository" "$repo"

if [[ ! "$token" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
  echo "ERROR: invalid Homebrew cask token: $token" >&2
  exit 1
fi

if [[ ! "$sha256" =~ ^[A-Fa-f0-9]{64}$ ]]; then
  echo "ERROR: sha256 must be a 64-character hex digest" >&2
  exit 1
fi

if [[ "$repo" != */* ]]; then
  echo "ERROR: repository must be in owner/name format: $repo" >&2
  exit 1
fi

for font_file in "$@"; do
  require_value "font file" "$font_file"
done

mkdir -p Casks

cask_path="Casks/${token}.rb"

{
  echo "cask \"${token}\" do"
  echo "  version \"${version}\""
  echo "  sha256 \"${sha256}\""
  echo
  echo "  url \"https://github.com/${repo}/releases/download/${tag}/${asset}\","
  echo "      verified: \"github.com/${repo}/\""
  echo "  name \"${name}\""
  echo "  desc \"${desc}\""
  echo "  homepage \"https://github.com/${repo}\""
  echo

  for font_file in "$@"; do
    echo "  font \"${font_file}\""
  done

  echo "end"
} > "$cask_path"

echo "Generated Homebrew cask: $cask_path"
