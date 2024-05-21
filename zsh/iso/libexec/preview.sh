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
    if [[ -v KITTY_PID ]]; then
      SIZE="$(kitten icat --print-window-size)"
      SIZE="${SIZE/x/,}"
      ARGS=(
        kitten
        icat
        --use-window-size "$FZF_PREVIEW_COLUMNS,$FZF_PREVIEW_LINES,$SIZE"
      )
    else
      ARGS=(
        chafa
      )
    fi
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
