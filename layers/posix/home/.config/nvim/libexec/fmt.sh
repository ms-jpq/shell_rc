#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

LIBEXEC="${0%/*}"
CFG="$LIBEXEC/.."
APRIORI="$CFG/apriori"

FILEPATH="$1"
EXT=".${FILEPATH##*.}"

read -r -d '' -- JQ <<- 'JQ' || true
(.[$ext] // empty) as $ft | ($fmt[0][$ft] // empty) | [.command] + (.args // []) | map(gsub("%{buffer_name}"; $fp)) | @sh
JQ

if CMD="$(jq -e --raw-output --slurpfile fmt "$APRIORI/fmt.json" --arg ext "$EXT" --arg fp "$FILEPATH" -- "$JQ" "$APRIORI/mappings.json")"; then
  eval -- "ARGV=($CMD)"

  # shellcheck disable=SC2154
  if ((${#ARGV[@]})) && command -v -- "${ARGV[0]}" > /dev/null; then
    exec -- "${ARGV[@]}"
  fi
fi

exec -- "$LIBEXEC/fmt.sed"
