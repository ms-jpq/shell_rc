#!/usr/bin/env -S -- bash

tp() {
  # shellcheck disable=SC2312
  tmux capture-pane -J -S - -E - -p | c
}
