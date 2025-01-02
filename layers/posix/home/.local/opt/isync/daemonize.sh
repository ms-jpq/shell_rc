#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

OUTLOOK_CHANNEL="$1"
OUTLOOK_ADDR="$2"

LAUNCH_AGENTS=~/Library/LaunchAgents
export -- CHANNEL WATCH_PATHS

for MDIR in ~/.local/share/maildir/*/; do
  CHANNEL="${MDIR%%/}"
  CHANNEL="${CHANNEL##*/}"
  WATCH="$(find "$MDIR" -type d -name new | sed -E 's#(.*)#<string>\1</string>#')"
  WATCH_PATHS=$'-->\n'"$WATCH"$'\n<!--'

  mkdir -v -p -- ~/.local/state/isync/mbsync."$CHANNEL".{watch,queue}

  envsubst < "${0%/*}/mbsync.channel.xml" | sponge -- "$LAUNCH_AGENTS"/mbsync."$CHANNEL".plist
  envsubst < "${0%/*}/../maildir/mnotify.channel.xml" | sponge -- "$LAUNCH_AGENTS"/mnotify."$CHANNEL".plist
  printf -- '%s\n' "$CHANNEL"
done

CHANNEL="$OUTLOOK_CHANNEL"
MAIL="$OUTLOOK_ADDR" envsubst < "${0%/*}/outlook.notify.channel.xml"
