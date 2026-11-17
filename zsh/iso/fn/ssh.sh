#!/usr/bin/env -S -- bash

ssh() {
  command -- ssh "$@"
  local -- ret=$?
  # shellcheck disable=SC2154
  "$XDG_CONFIG_HOME/zsh/libexec/term-reset.sh"
  return "$ret"
}
