#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

VIM="$(< "${0%/*}/keep-alived.vim")"

cd -- ~/

KITTEN=(
  kitten quick-access-terminal
  --override=start_as_hidden=yes
  --instance-group=edit
  -- nvim
  --listen ~/.cache/nvim/quic.sock
  -c "$VIM"
)

set -x
while :; do
  "${KITTEN[@]}" || :
done 2>&1 | ts '%H:%M:%S'
