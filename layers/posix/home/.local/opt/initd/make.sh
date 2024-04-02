#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

case "$OSTYPE" in
linux*)
  MAKE='gmake'
  ;;
darwin*)
  MAKE='gmake'
  ;;
msys)
  PATH="/usr/bin:$PATH"
  # shellcheck disable=SC2154
  LOCALAPPDATA="$(cygpath "$LOCALAPPDATA")"
  PATH="$LOCALAPPDATA/Microsoft/WindowsApps:$PATH"
  MAKE='make.exe'
  ;;
*)
  exit 1
  ;;
esac

cd -- "$(dirname -- "$0")"
exec -- "$MAKE" "$@"
