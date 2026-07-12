#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

exec >&2

DST="$1"
SRC="${2:-$(cat)}"
FMT="${FMT:-$SRC}"

case "$OSTYPE" in
linux* | darwin*)
  T='bsdtar'
  ;;
msys | cygwin)
  # shellcheck disable=SC2154
  T="$(cygpath -- "$SYSTEMROOT/system32/tar.exe")"
  ;;
*)
  set -x
  exit 1
  ;;
esac

TAR=("$T" --extract --file "$SRC" --directory "$DST")
if [[ $OSTYPE == linux* ]]; then
  TAR+=(--no-same-owner)
fi

case "$FMT" in
*.tar.bz | *.tar.bz2 | *.tbz | *.tbz2 | *.tar.gz | *.tgz | *.tar.xz | *.txz | *.tar.zst)
  "${TAR[@]}"
  ;;
*.zip | *.vsix | *.sit)
  "${TAR[@]}"
  ;;
*.gz)
  NAME="$DST/$(basename -- "$SRC")"
  gzip --decompress --keep --force --stdout -- "$SRC" > "$NAME"
  ;;
*.xz)
  NAME="$DST/$(basename -- "$SRC")"
  xz --decompress --keep --force --stdout -- "$SRC" > "$NAME"
  ;;
*)
  set -x
  exit 1
  ;;
esac

tee >&2 <<- EOF
$SRC
-> -> ->
$DST
EOF
