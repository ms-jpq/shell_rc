#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

DST='tee'
if [[ -t 1 ]]; then
  DST=~/.config/zsh/bin/c
fi

tmux capture-pane -J -S - -E - -p | "$DST"
