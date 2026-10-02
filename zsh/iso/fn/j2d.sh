#!/usr/bin/env -S -- bash

j2d() {
  set -o pipefail

  local -- tmp
  tmp="$(mktemp --directory)"
  cd -- "$tmp" || return 1

  ~/.local/libexec/j2d.py -- "$tmp"
}
