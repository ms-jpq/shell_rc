#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

if ! (($#)); then
  exit 1
fi

case "$1" in
man | less | autossh | htop | btm | nvim | lazygit | cmatrix | ncspot)
  exit
  ;;
/bin/sh)
  if [[ "${2:-""}" == /usr/bin/man ]]; then
    exit
  fi
  ;;
"$HOME/.local/opt/isomorphic-copy/tmp/python"* | "$HOME/.local/opt/pyradio/venv/bin/python"*)
  exit
  ;;
*) ;;
esac

# shellcheck disable=SC2154
case "$*" in
*"$XDG_CONFIG_HOME/zsh/bin/llm-q" | *asciiquarium)
  exit
  ;;
*"$HOME/.local/opt/pipes.sh/pipes.sh"* | *"$XDG_CONFIG_HOME/zsh/bin/pom"* | *"$XDG_CONFIG_HOME/zsh/bin/mq"* | *"$XDG_CONFIG_HOME/zsh/bin/rq"*)
  exit
  ;;
*) ;;
esac

printf -- '%s\n' "$@" >&2
exit 1
