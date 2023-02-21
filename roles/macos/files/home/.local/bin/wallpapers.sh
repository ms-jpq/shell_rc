#!/usr/bin/env -S -- bash -Eeuo pipefail -O nullglob -O globstar

ARGS=(
  rsync
  --recursive
  --links
  --perms
  --times
  --human-readable
  --info progress2
  --delete
  --
  root@freenas.t.home.arpa:/media/wallpapers/
  "$HOME/Library/Mobile Documents/com~apple~CloudDocs/桌面背景/"
)

exec -- "${ARGS[@]}"
