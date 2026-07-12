#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

SRC="$1"
DIR="$2"

if [[ -d $DIR/.git ]]; then
  git -C "$DIR" pull --no-tags --force
else
  git clone --depth 1 -- "$SRC" "$DIR"
fi
