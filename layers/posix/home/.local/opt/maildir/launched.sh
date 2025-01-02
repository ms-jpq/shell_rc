#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob

set -o pipefail
shopt -u failglob

CHANNEL="$1"
LABEL="mnotify.$CHANNEL"
shift -- 1

SOCK=(/tmp/kitty.*.sock)

if ! ((${#SOCK[@]})); then
  exit
fi

{
  for DIR in "$@"; do
    for MAIL in "$DIR"/*; do
      FROM="$(formail -c -x from: < "$MAIL")"
      SUBJECT="$(formail -c -x subject: < "$MAIL")"
      kitten @ --to "unix:${SOCK[*]}" -- kitten notify --icon info -- "📩 ↘ $FROM" "$SUBJECT"
      # ~/.local/libexec/notify.cjs "📩 ↘ $FROM" '' "$SUBJECT" ping
    done
  done
} 2>&1 | logger -t "$LABEL"
