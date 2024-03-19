#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

SRC="$1"
DST="$2"
NAME=${SRC##*/}
shift -- 2

CURL=(
  curl
  --fail-with-body
  --location
  --no-progress-meter
)

case "$OSTYPE" in
msys)
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
  -v
  "$@"
)

case "$SRC" in
*.tar.gz)
  "${CURL[@]}" -- "$SRC" | "${UNTAR[@]}" -z
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
