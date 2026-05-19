#!/usr/bin/env bash
set -euo pipefail

tag=""

normalize_tag() {
  local raw_tag="$1"

  if [ -z "$raw_tag" ] || [ "$raw_tag" = "null" ]; then
    return 0
  fi

  printf '%s\n' "$raw_tag"
}

if [ "${GITHUB_EVENT_NAME:-}" = "release" ]; then
  tag="${RELEASE_TAG_NAME:-}"
fi

if [ -z "$tag" ] && [ "${GITHUB_EVENT_NAME:-}" = "repository_dispatch" ]; then
  if [ -n "${DISPATCH_TAG_NAME:-}" ] && [ "$DISPATCH_TAG_NAME" != "null" ]; then
    tag="$DISPATCH_TAG_NAME"
  elif [ -n "${CLIENT_PAYLOAD:-}" ] && [ "$CLIENT_PAYLOAD" != "null" ]; then
    tag=$(printf '%s\n' "$CLIENT_PAYLOAD" | jq -r '.tag_name // empty')
  fi
fi

if [ -z "$tag" ] && [ "${GITHUB_EVENT_NAME:-}" = "workflow_dispatch" ]; then
  tag=$(normalize_tag "${MANUAL_TAG_NAME:-}")
fi

if [ -z "$tag" ]; then
  echo "ERROR: unable to determine release tag" >&2
  exit 1
fi

pkgver="$tag"

echo "tag=$tag" >> "$GITHUB_OUTPUT"
echo "pkgver=$pkgver" >> "$GITHUB_OUTPUT"
echo "Resolved tag=$tag pkgver=$pkgver"
