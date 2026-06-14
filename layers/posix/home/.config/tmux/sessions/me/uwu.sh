#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

ENV=TMUX_NO_SAVE
tmux set-environment -g -h -- "$ENV" 1

tmux new-window -c ~/Downloads
tmux select-pane -m
tmux set-buffer -- $'aerc \n'
tmux paste-buffer -d -p
tmux select-pane -t '{marked}'
tmux select-pane -M

tmux new-window -c "$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents"
tmux select-pane -m
tmux set-buffer -- $'yazi \n'
tmux paste-buffer -d -p
tmux select-pane -t '{marked}'
tmux select-pane -M

tmux new-window -c ~/Downloads
tmux select-pane -m
tmux set-buffer -- $'~/.local/opt/ai/bin/notificationd \n'
tmux paste-buffer -d -p
tmux select-pane -t '{marked}'
tmux select-pane -M

tmux select-window -t :-2
tmux set-environment -g -h -u -- "$ENV"
