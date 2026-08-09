#!/usr/bin/env -S -- bash

# shellcheck disable=SC2312
if [[ -n ${TMUX:-} ]] && tmux display-message -p -- '#{window_panes}' | grep -E --quiet -v --line-regexp -e '^1$'; then
  tmux new-window -a -c '#{pane_current_path}' -- man "$@"
else
  command -- man "$@"
fi
