#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

cd -- "${0%/*}/.."

TARGET="$1"
shift -- 1

ENV='./libexec/env.sh'

if [[ "$TARGET" == 'localhost' ]]; then
  exec -- "$ENV"
else
  BASH=(bash -c "$(<"$ENV")")
  SH="$(printf -- '%q ' "${BASH[@]}")"
  # shellcheck disable=SC2029
  ssh "$@" "$TARGET" "$SH"
fi
