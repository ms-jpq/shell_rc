#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

CHANNEL="$1"
TRIGGER=~/.local/state/isync/mbsync."$CHANNEL".queue/trigger
touch -- "$TRIGGER"

while true; do
  if ! [[ -f $TRIGGER ]]; then
    break
  fi
  sleep -- 0.1
done
