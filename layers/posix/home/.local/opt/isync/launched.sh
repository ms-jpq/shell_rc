#!/usr/bin/env -S -- sh -Eeu

CHANNEL="$1"
/opt/homebrew/bin/mbsync --verbose -- "$CHANNEL"

exec -- find ~/.local/state/isync/mbsync."$CHANNEL".queue -mindepth 1 -delete
