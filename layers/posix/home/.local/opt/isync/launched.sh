#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob

set -o pipefail

CHANNEL="$1"
LABEL="mbsync.$CHANNEL"

{
  /opt/homebrew/bin/mbsync --verbose -- "$CHANNEL"

  find ~/.local/state/isync/"$LABEL".queue -mindepth 1 -delete
} 2>&1 | logger -t "$LABEL"
