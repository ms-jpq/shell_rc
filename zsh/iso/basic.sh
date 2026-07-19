#!/usr/bin/env -S -- bash

_less=(
  --QUIET
  --RAW-CONTROL-CHARS
  --follow-name
  --hilite-target
  --ignore-case
  --incsearch
  --mouse
  --no-histdups
  --no-paste
  --no-vbell
  --tabs=2
  --tilde
  --underline-special
  --use-color
  --wheel-lines=3
)
export -- PAGER='less'
printf -v LESS -- '%q ' "${_less[@]}"
unset -- _less
# shellcheck disable=SC2154
export -- LESS LESSHISTFILE="$XDG_STATE_HOME/shell_history/less"
export -- TIME_STYLE='long-iso'
export -- PERL_UNICODE='ASD'
# shellcheck disable=SC2154
export -- CURL_HOME="$XDG_CONFIG_HOME/curl"
