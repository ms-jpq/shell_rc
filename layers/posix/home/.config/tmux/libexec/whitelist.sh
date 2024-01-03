#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

if ! (($#)); then
  exit 1
fi

case "$1" in
man | less | nvim | autossh)
  exit
  ;;
/bin/sh)
  if [[ "${2:-""}" == /usr/bin/man ]]; then
    exit
  fi
  ;;
"$HOME/.local/opt/pyradio/venv/bin/python"*)
  exit
  ;;
*) ;;
esac

printf -- '%s\n' "$@" >&2
exit 1
