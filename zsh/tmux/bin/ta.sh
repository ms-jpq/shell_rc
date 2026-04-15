#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

SESSION="$*"

# shellcheck disable=2154
PLANNED_SESSION="$XDG_CONFIG_HOME/tmux/sessions/$SESSION.sh"

if [[ -s $PLANNED_SESSION ]]; then
  SESSION_SCRIPT="$PLANNED_SESSION"
elif (($#)); then
  # shellcheck disable=2154
  SESSION_SCRIPT="$XDG_STATE_HOME/tmux/$SESSION.1.sh"
else
  if ! SESSION="$(tmux list-sessions -F '#{session_name}' | fzf -0)"; then
    exit
  fi
  SESSION_SCRIPT="$XDG_STATE_HOME/tmux/$SESSION.1.sh"
fi

if [[ -f $SESSION_SCRIPT ]]; then
  # shellcheck disable=SC1090
  source -- "$SESSION_SCRIPT"
elif [[ -v TMUX ]]; then
  tmux new-session -d -c "$HOME" -s "$SESSION"
  exec -- tmux switch-client -t "$SESSION"
else
  exec -- tmux new-session -A -c "$HOME" -s "$SESSION"
fi
