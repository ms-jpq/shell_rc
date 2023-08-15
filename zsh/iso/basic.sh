#!/usr/bin/env -S -- bash

_less=(
  --quit-on-intr
  --quit-if-one-screen
  --mouse
  --RAW-CONTROL-CHARS
  --tilde
  --tabs=2
  --QUIET
  --ignore-case
  --no-histdups
)
export -- PAGER='less'
printf -v LESS -- '%q ' "${_less[@]}"
unset -- less
# shellcheck disable=SC2154
export -- LESS LESSHISTFILE="$XDG_STATE_HOME/shell_history/less"

export -- TIME_STYLE='long-iso'
# shellcheck disable=SC2154
export -- EDITOR="$XDG_CONFIG_HOME/zsh/libexec/edit.sh"
export -- MANPAGER='nvim +Man! --'

export -- CURL_HOME="$XDG_CONFIG_HOME/curl"
