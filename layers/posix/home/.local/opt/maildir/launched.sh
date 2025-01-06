#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob

set -o pipefail
shopt -u failglob

if [[ -v RECURSION ]]; then
  SOCK=(/tmp/kitty.*.sock)

  MAIL="$1"
  FROM="$(mhdr -d -h from -- "$MAIL")"
  SUBJECT="$(mhdr -d -h subject -- "$MAIL")"
  ID="$(b3sum --length 16 <<< "$MAIL" | cut -d ' ' -f 1)"

  if ((${#SOCK[@]})); then
    /Applications/kitty.app/Contents/MacOS/kitten @ --to "unix:${SOCK[*]}" -- kitten notify --identifier "$ID" --icon info -- "📩 ↘ $FROM" "$SUBJECT"
  else
    ~/.local/libexec/notify.cjs "📩 ↘ $FROM" '' "$SUBJECT" ping
  fi

  exit
fi

CHANNEL="$1"
LABEL="mnotify.$CHANNEL"
shift -- 1

{
  for DIR in "$@"; do
    for MAIL in "$DIR"/*; do
      printf -- '%s\0' "$MAIL"
    done
  done | RECURSION=1 xargs -r -0 -P 0 -I % -- ~/.local/opt/maildir/launched.sh %
} 2>&1 | logger -t "$LABEL"
