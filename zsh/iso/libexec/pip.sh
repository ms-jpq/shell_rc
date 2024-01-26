#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

EXECUTE=(pip "$@")

IS_VENV=0
if [[ -v VIRTUAL_ENV ]]; then
  IS_VENV=1
fi

IS_INTERACTIVE=0
if [[ -t 0 ]]; then
  IS_INTERACTIVE=1
fi

IS_INSTALL=0
if [[ "${EXECUTE[1]:-""}" == 'install' ]]; then
  IS_INSTALL=1
fi
for ARG in "$@"; do
  case "$ARG" in
  -h | --help)
    IS_INSTALL=0
    ;;
  *) ;;
  esac
done

ASK=0
if ! ((IS_VENV)) && ((IS_INTERACTIVE)) && ((IS_INSTALL)); then
  ASK=1
fi

if ! ((ASK)); then
  exec -- "${EXECUTE[@]}"
else
  # shellcheck disable=SC2154
  HR="$("$XDG_CONFIG_HOME/zsh/libexec/hr.sh" '-')"

  {
    type -a python3
    printf -- '%s\n' "$HR"
    printf -- '%s\n' 'Not in virtual environment:'
    printf -- '%s\n' "$HR"
    printf -- '%s\n' "${EXECUTE[*]}"
    printf -- '%s\n' "$HR"
  } >&2

  read -r -p 'Continue (y/n)?' -- CONT
  case "$CONT" in
  1 | y | Y)
    exec -- "${EXECUTE[@]}"
    ;;
  *)
    exit 130
    ;;
  esac
fi
