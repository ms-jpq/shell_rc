#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

cd -- "${0%/*}/.."

read -r -d '' -- JQ <<-'JQ' || true
to_entries | map("\(.key) \($src[][.value])")[]
JQ

jq --raw-output --slurpfile src ./layers/posix/home/.config/ttyd/theme.json "$JQ" <./layers/posix/home/.config/kitty/map.json
