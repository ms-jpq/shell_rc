#!/usr/bin/env -S -- bash

th() {
  local dump
  dump="$(tmux capture-pane -p -S -)"
  fzf <<<"$dump"
}
