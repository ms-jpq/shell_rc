#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

INPUT="$*"

case "$INPUT" in
*/)
  exec -- mkdir -p -- "$INPUT"
  ;;
*)
  DIR="$(dirname -- "$INPUT")"
  mkdir -p -- "$DIR"
  exec -- touch -- "$INPUT"
  ;;
esac

if [[ -v LF_LEVEL ]] && [[ -v id ]] ; then
  lf -remote "send $id select $INPUT"
fi
