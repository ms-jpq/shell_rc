#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

SRC="$1"
shift -- 1

LIB="$HOME/.cache/helix-rt/nvim/pack"

case "${1:-}" in
--lazy)
  LIB="$LIB/opt"
  shift -- 1
  ;;
*)
  LIB="$LIB/start"
  ;;
esac
DST="$LIB/${SRC##*/}"

~/.local/opt/initd/libexec/git-sync.sh "$SRC" "$DST"

printf -- '%s\n' "-> $SRC" >&2

if (($#)); then
  pushd -- "$DST" > /dev/null
  exec -- "$@"
fi
