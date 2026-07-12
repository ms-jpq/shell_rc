#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

FILE="$1"
shift -- 1

ARGV=()
if [[ $1 == '-' ]]; then
  ARGV=("$@")
else
  ARGV=(-o IdentitiesOnly=yes -i "$HOME/.ssh/$FILE" "$@")
fi

exec -- ssh "${ARGV[@]}"
