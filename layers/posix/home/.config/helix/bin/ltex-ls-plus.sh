#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

exec -- "$HOME/.cache/helix-rt/more/ltex-plus.sh/bin/ltex-ls-plus" "$@"
