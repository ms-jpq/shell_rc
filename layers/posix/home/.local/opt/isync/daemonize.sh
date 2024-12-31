#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

for MDIR in ~/.local/share/maildir/*/; do
  NAME="${MDIR%%/}"
  NAME="${NAME##*/}"
  mkdir -v -p -- ~/.local/state/isync/mbsync."$NAME".{watch,queue}
  CHANNEL="$NAME" envsubst < "${0%/*}/mbsync.channel.xml" | tee -- ~/Library/LaunchAgents/mbsync."$NAME".plist
done
