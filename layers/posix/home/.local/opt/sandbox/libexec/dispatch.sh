#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

case "$OSTYPE" in
darwin*)
  exec -- "${0%/*}/sb-exec.sh" "$@"
  ;;
*)
  exec -- "${0%/*}/bubble-wrap.sh" "$@"
  ;;
esac
