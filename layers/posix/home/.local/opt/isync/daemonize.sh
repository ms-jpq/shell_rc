#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

LAUNCH_AGENTS=~/Library/LaunchAgents
export -- CHANNEL WATCH_PATHS

for MDIR in ~/.local/share/maildir/*/; do
  CHANNEL="${MDIR%%/}"
  CHANNEL="${CHANNEL##*/}"
  WATCH="$(find "$MDIR" -type d -name new | sed -E 's#(.*)#<string>\1</string>#')"
  WATCH_PATHS=$'-->\n'"$WATCH"$'\n<!--'

  mkdir -v -p -- ~/.local/state/isync/mbsync."$CHANNEL".queue

  DST1="$LAUNCH_AGENTS"/mbsync."$CHANNEL".plist
  DST2="$LAUNCH_AGENTS"/mnotify."$CHANNEL".plist
  FILES=("$DST1" "$DST2")
  envsubst < "${0%/*}/mbsync.channel.xml" | sponge -- "$DST1"
  envsubst < "${0%/*}/../maildir/mnotify.channel.xml" | sponge -- "$DST2"

  for FILE in "${FILES[@]}"; do
    chronic -- launchctl load "$FILE"
  done

  printf -- '%s\n' "$CHANNEL"
done
