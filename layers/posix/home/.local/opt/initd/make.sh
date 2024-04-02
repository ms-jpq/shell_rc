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
  shopt -u failglob
  # shellcheck disable=SC2154
  LOCALAPPDATA="$(/usr/bin/cygpath -- "$LOCALAPPDATA")"
  PY=(
    "$LOCALAPPDATA/Programs/Python"/Python*/
    /usr/bin
    "$PATH"
  )
  IFS=':'
  PATH="${PY[*]}"
  unset -- IFS
  MAKE='make.exe'
  export -- MSYSTEM='MSYS' MSYS='winsymlinks:nativestrict'
  ;;
*)
  exit 1
  ;;
esac

cd -- "$(dirname -- "$0")"
exec -- "$MAKE" "$@"
