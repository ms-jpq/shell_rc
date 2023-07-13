#!/usr/bin/env -S -- bash

z() {
  # shellcheck disable=SC2154
  if [[ ! -v _Z_CMD ]]; then
    _Z_DATA="$XDG_STATE_HOME/zz"
    # shellcheck disable=SC1091
    _Z_CMD='__z' source -- "$HOME/.local/opt/z/z.sh"
  fi

  local -- acc
  acc="$(_z -l "$*" 2>&1)"
  acc="$(sd 's/^[[:digit:]]\+[[:space:]]\+\|common://g' <<<"$acc")"
  acc="$(awk '!seen[$0]++' <<<"$acc")"

  if [[ -z "$acc" ]]; then
    printf -- '%s\n' "MIA: $*"
  else
    acc="$(fp -1 +s --tac <<<"$acc")"
    cd -- "$acc" || return 1
  fi
}
