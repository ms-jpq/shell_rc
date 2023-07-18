#!/usr/bin/env -S -- bash

tmux-ssh() {
  if ! [[ -v TMUX ]]; then
    return
  fi

  if ! [[ -v SSH_CLIENT ]]; then
    return
  fi

  local -- DIR='/tmp/tmux-status-line'
  local -- IP="${SSH_CLIENT%% *}"
  local -- TMUX="${TMUX%%,*}"
  local -- NAME="$DIR/${TMUX//\//|}"

  mkdir -p -- "$DIR"
  printf -- '%s' "$IP" >"$NAME.ip2"
  mv -- "$NAME.ip2" "$NAME.ip"
}
