#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

DST="$1"
shift -- 1

mkdir -v -p -- "$DST"

set -x

CP=(-a -f)
if [[ $OSTYPE == msys ]]; then
  CP+=(--dereference)
  tree -L 2 -- "$@"
fi

for SRC in "$@"; do
  if [[ -d $SRC ]]; then
    cp "${CP[@]}" -- "$SRC"/* "$DST"
  fi
done

touch -- "$DST"
