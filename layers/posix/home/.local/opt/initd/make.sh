#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O globstar

set -o pipefail

case "$OSTYPE" in
linux*)
  MAKE='gmake'
  ;;
darwin*)
  MAKE='gmake'
  ;;
msys)
  # shellcheck disable=SC2154
  LOCALAPPDATA="$(/usr/bin/cygpath "$LOCALAPPDATA")"
  PY=(
    "$LOCALAPPDATA/Programs/Python"/Python*/
    /usr/bin
    "$PATH"
  )
  IFS=':'
  PATH="${PY[*]}"
  unset -- IFS
  MAKE='make.exe'
  export -- MSYSTEM='MSYS'
  ;;
*)
  exit 1
  ;;
esac

cd -- "$(dirname -- "$0")"
exec -- "$MAKE" "$@"
