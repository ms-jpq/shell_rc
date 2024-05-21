#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

if [[ -v KITTY_PID ]]; then
  if [[ -v FZF_PREVIEW_COLUMNS ]]; then
    ARGV=(
      --stdin no
      --place "${FZF_PREVIEW_COLUMNS}x$FZF_PREVIEW_LINES@0x0"
    )
  else
    ARGV=()
  fi

  ARGV+=(
    --transfer-mode memory
    "$@"
  )
  exec -- kitten icat "${ARGV[@]}"
else
  exec -- chafa "$@"
fi
