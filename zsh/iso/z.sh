#!/usr/bin/env -S -- bash

# shellcheck disable=SC2154
if [[ ! -v _Z_CMD ]]; then
  _Z_DATA="$XDG_STATE_HOME/zsh/zz"
  # shellcheck disable=SC1091
  _Z_CMD='__z'
fi

z() {
  local -- acc
  acc="$(_z -l "$*" 2>&1)"
  # shellcheck disable=SC2001
  acc="$(sed -E -e 's/^([[:digit:]]+|common:)[[:space:]]+//g' <<< "$acc")"
  acc="$(awk '!seen[$0]++' <<< "$acc")"

  if [[ -z $acc ]]; then
    printf -- '%s\n' "MIA: $*"
  else
    acc="$(fp +s --tac <<< "$acc")"
    cd -- "$acc" || return 1
  fi
}
