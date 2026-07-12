#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

case "$OSTYPE" in
darwin*)
  ARGV=(open -- "obsidian://$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/$*")
  ;;
linux*)
  ARGV=(xdg-open "obsidian://$*")
  ;;
msys | cygwin)
  ARGV=(start "obsidian://$*")
  ;;
*)
  set -x
  exit 1
  ;;
esac

exec -- "${ARGV[@]}"
