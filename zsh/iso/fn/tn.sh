#!/usr/bin/env -S -- bash

if [[ -n ${TMUX:-} ]]; then
  tmux new-window -a -c '#{pane_current_path}' -- "$@"
else
  "$@"
fi
