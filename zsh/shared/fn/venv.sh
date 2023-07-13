#!/usr/bin/env -S -- bash

venv() {
  local -- src
  # shellcheck disable=SC2154
  src="$(command -- "$ZDOTDIR/libexec/venv.sh" "$@")"
  eval -- "$src"
}
