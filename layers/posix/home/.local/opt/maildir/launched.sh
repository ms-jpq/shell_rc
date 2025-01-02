#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

CHANNEL="$1"
LABEL="mnotify.$CHANNEL"
shift -- 1

{
  if find "$@" -type f | grep -E -- .; then
    ~/.local/libexec/notify.cjs "📩 ↘ $CHANNEL" '' '-' ping
  fi
} 2>&1 | logger -t "$LABEL"
