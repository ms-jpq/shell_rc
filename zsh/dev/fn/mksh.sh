#!/usr/bin/env -S -- bash

mksh() {
  local -- name="$*"

  touch -- "$name"
  chmod -- +x "$name"
  # shellcheck disable=SC2154
  $EDITOR "$name"
}
