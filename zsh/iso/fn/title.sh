#!/usr/bin/env -S -- bash

if [[ -v TMUX ]]; then
  # OSC 2 -> set pane_title
  # shellcheck disable=SC1003
  printf -- '\e]2;%s\e\\' "$*"
else
  # OSC 0 -> set terminal icon
  # shellcheck disable=SC1003
  printf -- '\e]0;%s\e\\' "$*"
fi
