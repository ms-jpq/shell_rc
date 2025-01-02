#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob

set -o pipefail
shopt -u failglob

CHANNEL="$1"
LABEL="mnotify.$CHANNEL"
shift -- 1

{
  for DIR in "$@"; do
    for MAIL in "$DIR"/*; do
      FROM="$(formail -X from: < "$MAIL" | sed -E -e 's/^(F|f)rom: //')"
      SUBJECT="$(formail -X subject: < "$MAIL" | sed -E -e 's/^(S|s)ubject: //')"
      ~/.local/libexec/notify.cjs "📩 ↘ $FROM" '' "$SUBJECT" ping
    done
  done
} 2>&1 | logger -t "$LABEL"
