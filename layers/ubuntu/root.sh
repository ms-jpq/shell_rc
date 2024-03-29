#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

link() {
  local -- src="$1" dst="$2"

  if ! [[ -L "$dst" ]]; then
    mkdir -v -p -- "${dst%/*}"
    ln -v -sf -- "$src" "$dst"
  fi
}

link /dev/null /usr/local/lib/systemd/system/motd-news.timer
link /dev/null /usr/local/lib/systemd/system/update-notifier-motd.timer
