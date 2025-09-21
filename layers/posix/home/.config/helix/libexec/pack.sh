#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

SRC="$1"
shift -- 1

LIB="$HOME/.cache/helix-rt/nvim/pack"

case "${1:-""}" in
--lazy)
  LIB="$LIB/opt"
  shift -- 1
  ;;
*)
  LIB="$LIB/start"
  ;;
esac
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

if (($#)); then
  pushd -- "$DST" > /dev/null
  exec -- "$@"
fi
