#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

DEST_DIR="$PWD"

for SRC in "$@"; do
  BASE="${SRC##*/}"

  if [[ $BASE == .*.* ]]; then
    STEM="${BASE%.*}"
    EXT=".${BASE##*.}"
  elif [[ $BASE == .* || $BASE != *.* ]]; then
    STEM="$BASE"
    EXT=""
  else
    STEM="${BASE%.*}"
    EXT=".${BASE##*.}"
  fi

  NAME="$BASE"
  N=1
  while [[ -e $DEST_DIR/$NAME || -L $DEST_DIR/$NAME ]]; do
    NAME="${STEM}_$((N++))${EXT}"
  done

  REL="$(realpath --no-symlinks --relative-to="$DEST_DIR" -- "$SRC")"
  ln --symbolic -- "$REL" "$DEST_DIR/$NAME"
done
