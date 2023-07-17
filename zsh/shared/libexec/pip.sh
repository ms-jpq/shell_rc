#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

bin="${0%/*}"

# shellcheck disable=SC2154
PATH="$("$ZDOTDIR/libexec/path.sh" remove "$bin")"

EXECUTE=(
  "${0##*/}"
  "$@"
)

IS_VENV=0
if [[ -v VIRTUAL_ENV ]]; then
  IS_VENV=1
fi

IS_INTERACTIVE=0
if [[ -t 0 ]]; then
  IS_INTERACTIVE=1
fi

IS_INSTALL=0
if [[ $# -gt 0 ]] && [[ "${EXECUTE[1]}" == 'install' ]]; then
  IS_INSTALL=1
fi
for ARG in "$@"; do
  if [[ "$ARG" == '-h' ]] || [[ "$ARG" == '--help' ]]; then
    IS_INSTALL=0
  fi
done

ASK=0
if ! ((IS_VENV)) && ((IS_INTERACTIVE)) && ((IS_INSTALL)); then
  ASK=1
fi

if ! ((ASK)); then
  exec -- "${EXECUTE[@]}"
else
  HR="$("$ZDOTDIR/libexec/hr.sh" '-')"

  type >&2 -a python3
  printf >&2 -- '%s\n' "$HR"
  printf >&2 -- '%s\n' 'Not in virtual environment:'
  printf >&2 -- '%s\n' "$HR"
  printf >&2 -- '%s\n' "${EXECUTE[*]}"
  printf >&2 -- '%s\n' "$HR"

  read -r -p 'Continue (y/n)?' -- CONT
  case "$CONT" in
  1 | y | Y)
    exec -- "${EXECUTE[@]}"
    ;;
  *)
    exit 1
    ;;
  esac
fi
