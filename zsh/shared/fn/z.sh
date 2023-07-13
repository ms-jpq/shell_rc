#!/usr/bin/env -S -- bash

z() {
  if [[ ! -v _Z_CMD ]]; then
    _Z_DATA="$XDG_CACHE_HOME/zz"
    _Z_CMD='__z' source -- "$ZDOTDIR/../z/z.sh"
  fi

  local -- A=
  A="$(_z -l "$*" 2>&1)"
  local -- B=
  B="$(sd '^[[\d|\.]|common:]+\s+' '' <<<"$A" | awk '!seen[$0]++')"
  if [[ -z "$B" ]]; then
    printf -- '%s\n' "no such file or directory: $*"
  else
    local -- C=
    C="$(fp -1 +s --tac <<<"$B")"
    cd -- "$C" || return 1
  fi
}