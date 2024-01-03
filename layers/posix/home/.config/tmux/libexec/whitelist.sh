#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

if ! (($#)); then
  exit 1
fi

case "$1" in
/bin/sh | /bin/bash | /usr/bin/bash | /usr/bin/zsh | /opt/homebrew/bin/bash | /opt/homebrew/bin/zsh)
  shift
  ;;
*) ;;
esac

case "$1" in
/usr/bin/man | less | nvim)
  exit
  ;;
*) ;;
esac

case "$1" in
"$HOME/.local/opt/pyradio/venv/bin/python"*)
  exit
  ;;
*) ;;
esac

printf -- '%s\n' "$@" >&2
exit 1
