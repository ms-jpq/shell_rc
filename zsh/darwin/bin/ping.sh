#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

case "$OSTYPE" in
darwin*)
  ARGV=(gping --simple-graphics --color magenta "$@")
  ;;
linux*)
  ARGV=(/usr/bin/ping "$@")
  ;;
msys)
  ARGV=("$0" "$@")
  ;;
*) ;;
esac

exec -- "${ARGV[@]}"
