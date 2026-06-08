#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
usage:
  release-tags.sh timestamp
  release-tags.sh upstream-marker <nerd-tag> <sarasa-tag>

Generates release-related tag names for CI.
EOF
}

is_blank_or_null() {
  local value="${1:-}"
  [ -z "$value" ] || [ "$value" = "null" ]
}

sanitize_tag_part() {
  local value="$1"

  printf '%s' "$value" | sed -E 's/[^A-Za-z0-9._-]+/-/g; s/^-+//; s/-+$//'
}

require_value() {
  local name="$1"
  local value="$2"

  if is_blank_or_null "$value"; then
    echo "ERROR: $name is required" >&2
    exit 1
  fi
}

timestamp_tag() {
  date -u +'%Y.%m.%d-%H%M%S'
}

upstream_marker_tag() {
  local nerd_tag="$1"
  local sarasa_tag="$2"
  local nerd_part
  local sarasa_part

  require_value "nerd tag" "$nerd_tag"
  require_value "sarasa tag" "$sarasa_tag"

  nerd_part="$(sanitize_tag_part "$nerd_tag")"
  sarasa_part="$(sanitize_tag_part "$sarasa_tag")"

  require_value "sanitized nerd tag" "$nerd_part"
  require_value "sanitized sarasa tag" "$sarasa_part"

  printf 'jetbrains-%s-sarasa-%s\n' "$nerd_part" "$sarasa_part"
}

command="${1:-}"
case "$command" in
  timestamp)
    if [ "$#" -ne 1 ]; then
      usage
      exit 2
    fi
    timestamp_tag
    ;;
  upstream-marker)
    if [ "$#" -ne 3 ]; then
      usage
      exit 2
    fi
    upstream_marker_tag "$2" "$3"
    ;;
  *)
    usage
    exit 2
    ;;
esac
