#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail
set -x

SRC="$1"
DST="$2"
NAME=${SRC##*/}

CURL=(
  curl --fail
  --location
  --no-progress-meter
  -- "$SRC"
)

case "$OSTYPE" in
msys*)
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
)

case "$SRC" in
*.tar.gz)
  "${CURL[@]}" | "${UNTAR[@]}" -z
  ;;
*.zip)
  FILE="$DST/$NAME"
  "${CURL[@]}" >"$FILE"
  unzip -o -d "$DST" "$FILE"
  ;;
*)
  "${CURL[@]}" >"$DST/$NAME"
  ;;
esac
