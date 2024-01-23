#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

ARGV=(
  rlwrap
  --one-shot
  --history-no-dupes 2
  --substitute-prompt '>: '
  --prompt-colour=red
  --command-name "${*##*/}"
  -- cat
)

exec -- "${ARGV[@]}"
