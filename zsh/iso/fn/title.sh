#!/usr/bin/env -S -- bash

# shellcheck disable=SC1003
if [[ -v TMUX ]]; then
  # ??
  printf -- '\ek%s\e\\' "$*"
else
  # OSC 0 -> Update Title
  printf -- '\e]0;%s\e\' "$*"
fi
