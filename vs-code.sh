#!/usr/bin/env bash

set -Eeu
set -o pipefail
shopt -s globstar nullglob


cd -- "$(dirname -- "$0")" || exit 1

DEST="$*"
UNITS=()

for unit in ./systemd/*
do
  UNITS+=("$(basename -- "$unit")")
done

rsync --recursive --links --perms --times --human-readable --info progress2 -- ./systemd/ "$DEST:/usr/local/lib/systemd/user/"

ssh "$DEST" systemctl --user daemon-reload
ssh "$DEST" systemctl --user enable --now -- "${UNITS[*]}"
