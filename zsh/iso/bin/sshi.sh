#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

file="$HOME/.ssh/$1"
shift -- 1

argv=()
if [[ $file == '-' ]]; then
  argv=("$@")
else
  argv=(-o IdentitiesOnly=yes -i "$file" "$@")
fi

exec -- ssh "${argv[@]}"
