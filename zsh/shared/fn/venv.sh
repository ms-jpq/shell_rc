#!/usr/bin/env -S -- bash

venv() {
  local -- src
  # shellcheck disable=SC2154
  src="$("$ZDOTDIR/libexec/venv.sh" "$@")"
  eval -- "$src"
}
