#!/usr/bin/env -S -- bash

cdt() {
  local tmp
  tmp="$(mktemp --directory)"
  cd -- "$tmp" || return 1
  if [[ -n "$1" ]]; then
    # shellcheck disable=SC2154
    $EDITOR "$1"
  fi
}
