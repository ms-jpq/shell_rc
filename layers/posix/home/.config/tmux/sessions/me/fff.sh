#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

ENV=TMUX_NO_SAVE
tmux set-environment -g -h -- "$ENV" 1

tmux new-window -c ~/dev.localized/scratch
tmux set-buffer -- $'claude --continue || claude --name scratch\n'
tmux paste-buffer -d -p
tmux split-window -c ~/dev.localized/scratch
tmux select-pane -m
tmux set-buffer -- $'nvim\n'
tmux paste-buffer -d -p
tmux select-pane -t \{marked\}
tmux select-pane -M
tmux select-layout -- even-horizontal

# tmux select-window -t :-2
tmux set-environment -g -h -u -- "$ENV"
