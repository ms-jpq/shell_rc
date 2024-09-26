#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

SYSTEMD=/usr/local/lib/systemd/system

declare -A -- LINKS=()
LINKS=(
  ["$SYSTEMD/motd-news.timer"]=/dev/null
  ["$SYSTEMD/update-notifier-motd.timer"]=/dev/null
)

for FROM in "${!LINKS[@]}"; do
  TO="${LINKS["$FROM"]}"
  if ! [[ -L $FROM ]]; then
    mkdir -v -p -- "${FROM%/*}"
    ln -v -snf -- "$TO" "$FROM"
  fi
done
