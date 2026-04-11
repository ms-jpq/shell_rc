#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob

set -o pipefail
shopt -u failglob

STATE="$HOME/.local/state/notify-mails"

if [[ -v RECURSION ]]; then
  SOCK=(/tmp/kitty.*.sock)

  MAIL="$1"
  ID="$(b3sum --length 16 <<< "$MAIL" | cut -d ' ' -f 1)"
  SID="$STATE/$ID"
  find "$STATE" -type f -mtime +7 -delete

  if ! (
    set -C
    true > "$SID"
  ) 2> /dev/null; then
    exit
  fi

  FROM="$(mhdr -d -h from -- "$MAIL")"
  SUBJECT="$(mhdr -d -h subject -- "$MAIL")"

  if ((${#SOCK[@]})); then
    ARGV=(
      ~/.local/libexec/notify.kitty.sh "${SOCK[*]}"
      "📩 ↘ $FROM" "$SUBJECT"
      --identifier "$ID"
      --icon info
    )
    "${ARGV[@]}"
  else
    ~/.local/libexec/notify.cjs "📩 ↘ $FROM" '' "$SUBJECT" ping
  fi

  exit
fi

CHANNEL="$1"
LABEL="mnotify.$CHANNEL"
shift -- 1

{
  if [[ -f "$STATE/$CHANNEL.silent" ]]; then
    exit
  fi
  RECURSION=1 find "$@" -maxdepth 1 -type f -exec ~/.local/opt/maildir/launched.sh '{}' ';'
} 2>&1 | logger -t "$LABEL"
