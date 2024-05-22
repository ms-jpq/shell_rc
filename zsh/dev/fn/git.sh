#!/usr/bin/env -S -- bash

git() {
  if (($#)) && typeset -f "git-$1" > /dev/null; then
    local -- arg0="git-$1"
    shift
    "$arg0" "$@"
  else
    command -- git "$@"
  fi
}
