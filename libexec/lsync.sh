#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

DST="$1"
shift -- 1

mkdir -v -p -- "$DST"

for SRC in "$@"; do
  if [[ -d "$SRC" ]]; then
    cp -a -f -- "$SRC"/* "$DST"
  fi
done

touch -- "$DST"
