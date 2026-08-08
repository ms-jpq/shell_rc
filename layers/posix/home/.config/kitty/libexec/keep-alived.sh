#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

VIM="$(< "${0%/*}/keep-alived.vim")"

SOCK=~/.cache/nvim/quic.sock
KITTEN=(
  kitten quick-access-terminal
  --override=start_as_hidden=yes
  --instance-group=edit
  -- nvim
  --listen "$SOCK"
  -c "$VIM"
)

while :; do
  pkill -f -- '--instance-group=edit' || :
  while pgrep -f -- '--instance-group=edit' > /dev/null; do
    sleep -- 0.06
  done
  rm -fr -- "$SOCK"
  set -x
  "${KITTEN[@]}" || :
  set +x
  # sleep -- 1
done 2>&1 | ts '%H:%M:%S'
