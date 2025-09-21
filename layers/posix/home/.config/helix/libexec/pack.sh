#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

SRC="$1"
shift -- 1
LAZY="$*"

LIB="$HOME/.cache/helix-rt/nvim/pack"

if [[ -n $LAZY ]]; then
  LIB="$LIB/opt"
else
  LIB="$LIB/start"
fi
DST="$LIB/${SRC##*/}"

GET=(
  git
  clone
  --config core.symlinks=true
  --recurse-submodules
  --shallow-submodules
  --depth 1
  --quiet
  --
  "$SRC" "$DST"
)

PATCH=(
  git
  -C "$DST"
  pull
  --recurse-submodules
  --no-tags
  --force
  --quiet
)

if [[ -d $DST ]]; then
  "${PATCH[@]}"
else
  "${GET[@]}"
fi

printf -- '%s\n' "-> $SRC" >&2
