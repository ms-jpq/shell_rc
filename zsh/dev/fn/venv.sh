#!/usr/bin/env -S -- bash

venv() {
  local -- src
  # shellcheck disable=SC2154
  src="$("$XDG_CONFIG_HOME/zsh/libexec/venv.sh" "$@")"
  eval -- "$src"
}
