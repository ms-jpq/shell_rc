#!/usr/bin/env -S -- bash

# shellcheck disable=SC2312
tmux capture-pane -J -S - -E - -p | tr -s -- '\n' | nvim -c 'norm! ggGMzz'
