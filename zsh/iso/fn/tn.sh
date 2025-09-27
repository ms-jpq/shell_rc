#!/usr/bin/env -S -- bash

if [[ -v TMUX ]]; then
  tmux new-window -a -c '#{pane_current_path}' -- "$@"
else
  "$@"
fi
