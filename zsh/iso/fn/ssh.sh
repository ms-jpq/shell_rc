#!/usr/bin/env -S -- bash

ssh() {
  command -- ssh "$@"
  local -- ret=$?
  stty sane
  tput -- rmcup cnorm sgr0 rmacs
  if [[ -t 2 ]]; then
    printf -- '\033[>4m' >&2
  fi
  return "$ret"
}
