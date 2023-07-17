#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

SRC="$1"
DST="$2"

CURL=(
  curl --fail
  --location
  --no-progress-meter
  -- "$SRC"
)

case "$SRC" in
*.tar.gz)
  UNPACK=(
    tar -x -z
    -p -o -m
    -C "$DST"
    -f -
    -v
  )
  ;;
*.zip)
  UNPACK=(
    unzip
    -d "$DST"
    -
  )
  ;;
*)
  exit 1
  ;;
esac

"${CURL[@]}" | "${UNPACK[@]}"
