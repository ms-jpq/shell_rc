#!/usr/bin/env -S -- bash

tmux-edit() {
  local -- tmp
  tmp="$(mktemp)"
  tmux-dump >"$tmp"
  # shellcheck disable=SC2154
  "$EDITOR" "$tmp"
}
