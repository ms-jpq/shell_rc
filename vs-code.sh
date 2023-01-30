#!/usr/bin/env -S -- bash

set -Eeu
set -o pipefail
shopt -s globstar nullglob

cd -- "$(dirname -- "$0")" || exit 1

DEST="$*"
SYSTEMD='/usr/local/lib/systemd/system/'
UNITS=()

for unit in ./systemd/*; do
  UNITS+=("$(basename -- "$unit")")
done

ssh "$DEST" 'mkdir --parents -- '"$SYSTEMD"
rsync --recursive --links --perms --times --human-readable --info progress2 -- ./systemd/ "$DEST:$SYSTEMD"

ssh "$DEST" systemctl daemon-reload
ssh "$DEST" systemctl enable --now -- "${UNITS[*]}"
