#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

cleanup() {
  set -x
  kill -9 "-$PGID" || :
}

trap -- cleanup EXIT

~/.cache/helix-rt/more/ltex-plus.sh/bin/ltex-ls-plus &
PGID=$!

wait
