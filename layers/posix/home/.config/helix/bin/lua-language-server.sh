#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

exec -- "$HOME/.cache/helix-rt/more/lua-ls.lua/lib/bin/lua-language-server" "$@"
