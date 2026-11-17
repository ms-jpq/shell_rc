#!/usr/bin/env -S -- bash

ssh() {
  command -- ssh "$@"
  local -- ret=$?
  stty sane
  tput -- rmcup cnorm sgr0 rmacs
  if [[ -t 2 ]]; then
    printf -- '\033[>4m\033[?1000;1002;1003;1004;1005;1006;1015;1016l' >&2
  fi
  return "$ret"
}
