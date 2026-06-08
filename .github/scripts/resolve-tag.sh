#!/usr/bin/env bash
set -euo pipefail

tag=""

is_blank_or_null() {
  local value="${1:-}"
  [ -z "$value" ] || [ "$value" = "null" ]
}

normalize_tag() {
  local raw_tag="${1:-}"

  if is_blank_or_null "$raw_tag"; then
    return 0
  fi

  printf '%s\n' "$raw_tag"
}

validate_tag() {
  local value="$1"

  if [ -z "$value" ]; then
    echo "ERROR: unable to determine release tag" >&2
    exit 1
  fi

  case "$value" in
    *[[:space:]]*)
      echo "ERROR: release tag must not contain whitespace: $value" >&2
      exit 1
      ;;
  esac
}

if [ "${GITHUB_EVENT_NAME:-}" = "release" ]; then
  tag="${RELEASE_TAG_NAME:-}"
fi

if [ -z "$tag" ] && [ "${GITHUB_EVENT_NAME:-}" = "repository_dispatch" ]; then
  if ! is_blank_or_null "${DISPATCH_TAG_NAME:-}"; then
    tag="$DISPATCH_TAG_NAME"
  elif ! is_blank_or_null "${CLIENT_PAYLOAD:-}"; then
    if ! command -v jq >/dev/null 2>&1; then
      echo "ERROR: jq is required to parse repository_dispatch client_payload" >&2
      exit 1
    fi
    tag=$(printf '%s\n' "$CLIENT_PAYLOAD" | jq -r '.tag_name // empty')
  fi
fi

if [ -z "$tag" ] && [ "${GITHUB_EVENT_NAME:-}" = "workflow_dispatch" ]; then
  tag=$(normalize_tag "${MANUAL_TAG_NAME:-}")
fi

validate_tag "$tag"

pkgver="$tag"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  {
    echo "tag=$tag"
    echo "pkgver=$pkgver"
  } >> "$GITHUB_OUTPUT"
fi

echo "Resolved tag=$tag pkgver=$pkgver"
