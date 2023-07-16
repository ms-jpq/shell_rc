#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

cd -- "${0%/*}/.."

SRC="$1"
DST="$2"
shift -- 2

UNTAR=(
  tar -x
  -p -o
  -C /
  -f -
)
APPLY="$(printf -- '%q ' "${UNTAR[@]}")"

if [[ "$DST" == 'localhost' ]]; then
  "${UNTAR[@]}" <"$SRC"
else
  # shellcheck disable=SC2029
  ssh "$@" "$DST" "$APPLY" <"$SRC"
fi
