#!/usr/bin/env -S -- bash

ssh() {
  command -- ssh "$@"
  local -- ret=$?
  stty sane
  tput -- rmcup cnorm sgr0 rmacs
  return "$ret"
}
