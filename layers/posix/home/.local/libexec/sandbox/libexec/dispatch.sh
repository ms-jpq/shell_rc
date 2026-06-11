#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

ROOT="$(realpath -- "$0")"

case "$OSTYPE" in
darwin*)
  exec -- "${ROOT%/*}/sb-exec.sh" "$@"
  ;;
*)
  exec -- "${ROOT%/*}/bubble-wrap.sh" "$@"
  ;;
esac
