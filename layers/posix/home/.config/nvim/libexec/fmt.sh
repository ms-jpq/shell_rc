#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

CFG="${0%/*}/.."
APRIORI="$CFG/apriori"

FILEPATH="$1"
EXT=".${FILEPATH##*.}"

read -r -d '' -- JQ <<- 'JQ' || true
(.[$ext] // empty) as $ft | ($fmt[0][$ft] // empty) | [.command] + (.args // []) | @sh
JQ

CMD="$(jq -e --raw-output --arg ext "$EXT" --slurpfile fmt "$APRIORI/fmt.json" -- "$JQ" "$APRIORI/mappings.json")" || exit

eval "$CMD" < "$FILEPATH"
