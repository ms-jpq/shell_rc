#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail
shopt -u failglob

CHANNEL="$1"
LABEL="mbsync.$CHANNEL"

OPT='/opt/homebrew/opt'
BIN='/opt/homebrew/bin'

EXEC=(
  timeout
  --preserve-status
  --kill-after 1s
  600s
  "$BIN/mbsync"
  -- "$CHANNEL"
)

{
  SASL_PATH="$OPT/cyrus-sasl/lib/sasl2:$OPT/cyrus-sasl-xoauth2/lib/sasl2" "${EXEC[@]}"
  # "$BIN/notmuch" --config ~/.config/notmuch/"$CHANNEL"/config new

  find ~/.local/state/isync/"$LABEL".queue -mindepth 1 -delete
} 2>&1 | logger -t "$LABEL"
