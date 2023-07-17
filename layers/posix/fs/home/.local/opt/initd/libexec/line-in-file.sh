#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

FILE="$1"
MATCH="$2"
LINE="${3:-"$MATCH"}"

read -r -d '' -- AWK <<-'EOF' || true
BEGIN { SEEN = 0 }

{
  if ($0 == MATCH) { SEEN = 1 }

  print
}

END {
  if (!SEEN) { print LINE }
}
EOF

mkdir -p -- "${FILE%/*}"
touch -- "$FILE"

NEW="$(awk -v MATCH="$MATCH" -v LINE="$LINE" "$AWK" "$FILE")"
printf -- '%s' "$NEW" >"$FILE"
