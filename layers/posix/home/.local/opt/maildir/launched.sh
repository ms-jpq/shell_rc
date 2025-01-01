#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

CHANNEL="$1"
LABEL="mnotify.$CHANNEL"
shift -- 1

{
  ~/.local/libexec/notify.cjs "📩 ↘ $CHANNEL" ''
} 2>&1 | logger -t "$LABEL"
