#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

if [[ -v KITTY_PID ]]; then
  if [[ -v FZF_PREVIEW_COLUMNS ]]; then
    SIZE="$(kitten icat --print-window-size)"
    SIZE="${SIZE/x/,}"
    ARGV=(
      --use-window-size "$FZF_PREVIEW_COLUMNS,$FZF_PREVIEW_LINES,$SIZE"
      "$@"
    )
  else
    ARGV=("$@")
  fi
  exec -- kitten icat "${ARGV[@]}"
else
  exec -- chafa "$@"
fi
