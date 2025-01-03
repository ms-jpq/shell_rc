#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob

set -o pipefail
shopt -u failglob

CHANNEL="$1"
LABEL="mnotify.$CHANNEL"
shift -- 1

SOCK=(/tmp/kitty.*.sock)

{
  for DIR in "$@"; do
    for MAIL in "$DIR"/*; do
      FROM="$(mhdr -d -h from -- "$MAIL")"
      SUBJECT="$(mhdr -d -h subject -- "$MAIL")"

      if ((${#SOCK[@]})); then
        /Applications/kitty.app/Contents/MacOS/kitten @ --to "unix:${SOCK[*]}" -- kitten notify --icon info -- "📩 ↘ $FROM" "$SUBJECT"
      else
        ~/.local/libexec/notify.cjs "📩 ↘ $FROM" '' "$SUBJECT" ping
      fi

    done
  done
} 2>&1 | logger -t "$LABEL"
