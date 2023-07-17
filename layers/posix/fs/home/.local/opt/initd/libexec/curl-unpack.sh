#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

SRC="$1"
DST="$2"
NAME=${SRC##*/}

CURL=(
  curl --fail
  --location
  --no-progress-meter
  -- "$SRC"
)

case "$SRC" in
*.tar.gz)
  UNTAR=(
    tar -x -z
    -p -o -m
    -C "$DST"
    -f -
    -v
  )
  "${CURL[@]}" | "${UNTAR[@]}"
  ;;
*.zip)
  "${CURL[@]}" >"$DST/$NAME"
  unzip -d "$DST" "$DST/$NAME"
  ;;
*)
  "${CURL[@]}" | dd of="$DST/$NAME"
  ;;
esac
