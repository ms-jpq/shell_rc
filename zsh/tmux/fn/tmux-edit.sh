#!/usr/bin/env -S -- bash

tmux-edit() {
  local -- tmp
  tmp="$(mktemp)"
  trap 'rm --force -- "$tmp"' EXIT
  "$(dirname -- "$0")/tmux-dump" >"$tmp"
  # shellcheck disable=SC2154
  "$EDITOR" "$tmp"
}
