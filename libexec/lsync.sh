#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

DST="$1"
shift -- 1

mkdir -v -p -- "$DST"

CP=(-a -f)
case "$OSTYPE" in
msys | cygwin)
  CP+=(--dereference)
  ;;
*) ;;
esac

for SRC in "$@"; do
  if [[ -d $SRC ]]; then
    cp "${CP[@]}" -- "$SRC"/* "$DST"
  fi
done

touch -- "$DST"
