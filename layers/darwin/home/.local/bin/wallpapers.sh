#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

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
  freenas:/media/wallpapers/
  "$HOME/桌面背景/"
)

exec -- "${ARGS[@]}"
