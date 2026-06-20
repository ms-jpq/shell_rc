#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

ENV=TMUX_NO_SAVE
tmux set-environment -g -h -- "$ENV" 1

DIRS=(
  ~/dev.localized/scratch
  ~/dev.localized/shell_rc
  ~/.local/opt/ai
  ~/.local/opt/lab
)

for DIR in "${DIRS[@]}"; do
  NAME="${DIR##*/}"

  tmux new-window -c "$DIR"
  tmux set-buffer -- "claude --continue || claude --name ${NAME@Q}"$'\n'
  tmux paste-buffer -d -p
  tmux select-pane -m
  tmux split-window -c "$DIR"
  tmux set-buffer -- $'nvim\n'
  tmux paste-buffer -d -p
  tmux select-pane -t '{marked}'
  tmux select-pane -M
  tmux select-layout -- even-horizontal
done

tmux select-window -t :-$((${#DIRS[@]} - 1))
tmux set-environment -g -h -u -- "$ENV"
