#!/usr/bin/env -S -- bash

th() {
  local -- dump cap=(tmux capture-pane -p -S -)
  if [[ -t 1 ]]; then
    dump="$("${cap[@]}")"
    fzf <<<"$dump"
  else
    "${cap[@]}"
  fi
}
