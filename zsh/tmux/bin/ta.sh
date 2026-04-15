#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

SESSION="$*"
# shellcheck disable=2154
SESSION_SCRIPT="$XDG_STATE_HOME/tmux/$SESSION.1.sh"

if (($#)); then
  if [[ -f $SESSION_SCRIPT ]]; then
    # shellcheck disable=SC1090
    source -- "$SESSION_SCRIPT"
  elif [[ -v TMUX ]]; then
    tmux new-session -d -c "$HOME" -s "$SESSION"
    tmux switch-client -t "$SESSION"
  else
    tmux new-session -A -c "$HOME" -s "$SESSION"
  fi
else
  SESSION_SCRIPT="$(tmux list-sessions -F '#{session_name}')"
  SESSION="$(fzf -0 <<< "$SESSION_SCRIPT")"
  SESSION="${SESSION:-"owo"}"
  SESSION_SCRIPT="$XDG_STATE_HOME/tmux/$SESSION.1.sh"

  if [[ $? -ne 130 ]]; then
    if [[ -v TMUX ]]; then
      tmux switch -t "$SESSION"
    elif [[ -f $SESSION_SCRIPT ]]; then
      # shellcheck disable=SC1090
      source -- "$SESSION_SCRIPT"
    else
      tmux new-session -A -c "$HOME" -s "$SESSION"
    fi
  fi
fi
