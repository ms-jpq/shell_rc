#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

ENV=TMUX_NO_SAVE
tmux set-environment -g -h -- "$ENV" 1

DIRS=(
  ~/dev.localized/scratch ''
  ~/.local/opt/ai ''
  ~/dev.localized/shell_rc ''
  ~/dev.localized/lab 'denv .facts/mcp.env'
)

for ((I = 0; I < ${#DIRS[@]}; I += 2)); do
  DIR="${DIRS[I]}"
  PREFIX="${DIRS[I + 1]}"
  NAME="${DIR##*/}"
  LAUNCH="${PREFIX:+$PREFIX }claude"

  tmux new-window -c "$DIR"
  tmux set-buffer -- "$LAUNCH --resume ${NAME@Q} || $LAUNCH --name ${NAME@Q}"$'\n'
  tmux paste-buffer -d -p
  tmux select-pane -m
  tmux split-window -c "$DIR"
  tmux set-buffer -- $'nvim\n'
  tmux paste-buffer -d -p
  tmux select-pane -t '{marked}'
  tmux select-pane -M
  tmux select-layout -- even-horizontal
done

tmux select-window -t :-$((${#DIRS[@]} / 2 - 1))
tmux set-environment -g -h -u -- "$ENV"
