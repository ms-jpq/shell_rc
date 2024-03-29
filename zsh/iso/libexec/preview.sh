#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

TARGET="$1"

export -- PAGER='tee'

if [[ -d "$TARGET" ]]; then
  ARGS=(
    eza
    --all
    --group-directories-first
    --classify
    --header
    --icons
    --oneline
    --color=always
  )
else
  MIME="$(file --mime-type --brief -- "$TARGET")"

  case "$MIME" in
  image/*)
    ARGS=(
      chafa
    )
    ;;
  *)
    ARGS=(
      bat
      --color=always
    )
    ;;
  esac

fi

exec -- "${ARGS[@]}" -- "$TARGET"
