#!/usr/bin/env -S -- bash

if [[ -v TMUX ]]; then
  # OSC 2 -> set pane_title
  printf -- '\e]2;%s\e\\' "$*"
else
  # OSC 0 -> set terminal icon
  printf -- '\e]0;%s\e\\' "$*"
fi
