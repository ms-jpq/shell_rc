#!/usr/bin/env -S -- bash

tmux-edit() {
  local tmp
  tmp="$(mktemp)"
  trap 'rm --force -- "$tmp"' EXIT
  "$(dirname -- "$0")/tmux-dump" >"$tmp"
  "$EDITOR" "$tmp"
}
