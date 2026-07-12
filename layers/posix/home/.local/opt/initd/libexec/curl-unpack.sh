#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

SRC="$1"
DST="$2"
NAME=${SRC##*/}
shift -- 2

CURL=(
  curl
  --fail
  --location
  --no-progress-meter
)

case "$OSTYPE" in
msys | cygwin)
  # shellcheck disable=SC2154
  TAR="$SYSTEMROOT/system32/tar.exe"
  ;;
*)
  TAR=tar
  ;;
esac

UNTAR=(
  "$TAR" -x
  -p -o -m
  -C "$DST"
  -f -
  "$@"
)

case "$SRC" in
*.tar.gz | *.tgz)
  "${CURL[@]}" -- "$SRC" | "${UNTAR[@]}" -z
  ;;
*.tar.xz | *.txz)
  "${CURL[@]}" -- "$SRC" | "${UNTAR[@]}" -J
  ;;
*.zip)
  FILE="$DST/$NAME"
  "${CURL[@]}" --output "$FILE" -- "$SRC"
  unzip -o -d "$DST" "$FILE" "$@"
  ;;
*)
  "${CURL[@]}" --output "$DST/$NAME" -- "$SRC"
  ;;
esac
