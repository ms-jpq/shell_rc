#!/usr/bin/env -S -- bash

cdt() {
  local tmp
  tmp="$(mktemp --directory)"
  cd -- "$tmp" || return 1
  git init --quiet
  if (($#)); then
    "$@"
  fi
}
