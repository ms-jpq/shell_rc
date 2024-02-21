#!/usr/bin/env -S -- bash

tmux-ssh() {
  if ! [[ -v TMUX ]]; then
    return
  fi

  if ! [[ -v SSH_CLIENT ]]; then
    return
  fi

  local -- dir="${TMUX_TMPDIR:-/tmp}/tmux-status-line"
  local -- ip="${*:-"${SSH_CLIENT%% *}"}"
  local -- tmux="${TMUX%%,*}"
  tmux="$(jq --raw-input --raw-output '@uri' <<<"$tmux")"
  local -- name="$dir/$tmux"

  command -- mkdir -v -p -- "$dir"
  printf -- '%s' "$ip" >"$name.ip2"
  command -- mv -v -f -- "$name.ip2" "$name.ip"
}
