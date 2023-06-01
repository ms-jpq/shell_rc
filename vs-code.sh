#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

cd -- "$(dirname -- "$0")"

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
