#!/usr/bin/env -S -- bash

tmux-dump() {
  local dump
  dump="$(tmux capture-pane -p -J -S -)"
  tee <<<"$dump"
}
