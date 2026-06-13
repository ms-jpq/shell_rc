#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

BIN=~/.cache/helix-rt/more/lua-ls.lua/lib/bin/lua-language-server

if [[ -x $BIN ]]; then
  exec -- "$BIN" "$@"
fi

SELF="${0%/*}"
PATH=":$PATH:"
PATH="${PATH//:$SELF:/:}"
PATH="${PATH#:}"
PATH="${PATH%:}"

exec -- lua-language-server "$@"
