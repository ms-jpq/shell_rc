#!/usr/bin/env -S -- bash

ta() {
  tmux-ssh
  local -- session="$*"
  # shellcheck disable=2154
  local -- session_names="$XDG_STATE_HOME/tmux/$session.1.sh"
  if (($#)); then
    if [[ -f "$session_names" ]]; then
      # shellcheck disable=SC1090
      source -- "$session_names"
    elif [[ -v TMUX ]]; then
      tmux new-session -d -c "$HOME" -s "$session"
      tmux switch -t "$session"
    else
      tmux new-session -A -c "$HOME" -s "$session"
    fi
  else
    session_names="$(tmux list-sessions -F '#{session_name}')"
    session="$(fzf -0 -1 <<<"$session_names")"
    if [[ $? -ne 130 ]]; then
      if [[ -v TMUX ]]; then
        tmux switch -t "$session"
      else
        tmux new-session -A -c "$HOME" -s "${session:-owo}"
      fi
    fi
  fi
}
