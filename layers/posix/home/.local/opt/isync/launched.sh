#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob

set -o pipefail

CHANNEL="$1"
LABEL="mbsync.$CHANNEL"

OPT='/opt/homebrew/opt'
BIN='/opt/homebrew/bin'

{
  SASL_PATH="$OPT/cyrus-sasl/lib/sasl2:$OPT/cyrus-sasl-xoauth2/lib/sasl2" "$BIN/mbsync" -- "$CHANNEL"
  # "$BIN/notmuch" --config ~/.config/notmuch/"$CHANNEL"/config new

  find ~/.local/state/isync/"$LABEL".queue -mindepth 1 -delete
} 2>&1 | logger -t "$LABEL"
