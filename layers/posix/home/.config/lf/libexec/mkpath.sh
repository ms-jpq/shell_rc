#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

INPUT="$*"

case "$INPUT" in
*/)
  mkdir -p -- "$INPUT"
  ;;
*)
  DIR="$(dirname -- "$INPUT")"
  mkdir -p -- "$DIR"
  touch -- "$INPUT"
  ;;
esac

printf -v QUOTED -- '%q' "$INPUT"

# shellcheck disable=SC2154
exec -- lf -remote "send $id select $QUOTED"
