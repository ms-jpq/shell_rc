#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

declare -A -- LINKS=()
LINKS=(
  ['/usr/local/lib/systemd/system/motd-news.timer']=/dev/null
  ['/usr/local/lib/systemd/system/update-notifier-motd.timer']=/dev/null
)

for FROM in "${!LINKS[@]}"; do
  TO="${LINKS["$FROM"]}"
  if ! [[ -L "$FROM" ]]; then
    ln -v -sf -- "$TO" "$FROM"
  fi
done
