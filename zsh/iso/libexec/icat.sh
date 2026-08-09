#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

if [[ -n ${KITTY_PID:-} ]]; then
  if [[ -n ${FZF_PREVIEW_COLUMNS:-} ]]; then
    : "${FZF_PREVIEW_LINES?}"
    ARGV=(
      --stdin no
      --place "${FZF_PREVIEW_COLUMNS}x$FZF_PREVIEW_LINES@0x0"
    )
  else
    ARGV=()
  fi

  if [[ -n ${SSH_TTY:-} ]] && [[ -t 0 ]]; then
    MODE=stream
  else
    MODE=memory
  fi

  ARGV+=(
    --transfer-mode "$MODE"
    "$@"
  )
  exec -- kitten icat "${ARGV[@]}"
else
  exec -- chafa "$@"
fi
