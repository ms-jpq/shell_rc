#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

CHANNEL="$1"
LABEL="mnotify.$CHANNEL"
shift -- 1

{
  if find "$@" -type f -print0 | grep --null-data -E -- . > /dev/null; then
    ~/.local/libexec/notify.cjs "📩 ↘ $CHANNEL" '' '-' ping
  fi
} 2>&1 | logger -t "$LABEL"
