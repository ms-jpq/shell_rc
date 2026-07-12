#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

TARGET="$1"
shift -- 1

export -- PAGER='tee'

if [[ -d $TARGET ]]; then
  ARGV=(
    eza
    --all
    --group-directories-first
    --classify
    --header
    --icons
    --oneline
    --color=always
    "$@"
  )
else
  ARGV=(
    bat
    --force-colorization
    "$@"
  )
fi

exec -- "${ARGV[@]}" -- "$TARGET"
