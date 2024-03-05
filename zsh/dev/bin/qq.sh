#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

LIBEXEC="${0%/*}/../libexec"

case "$1" in
http)
  SH="$LIBEXEC/q-http.sh"
  shift -- 1
  ;;
graphql)
  SH="$LIBEXEC/q-graphql.sh"
  shift -- 1
  ;;
*)
  SH="$LIBEXEC/q-m4.sh"
  ;;
esac

exec -a "$SH" -- "$SH" "$@"
