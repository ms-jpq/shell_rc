#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

SESSION="$*"

# shellcheck disable=2154
PLANNED_SESSION="$XDG_CONFIG_HOME/tmux/sessions/$SESSION.sh"

if TMUX_SESSIONS="$(tmux list-sessions -F '#{session_name}')"; then
  readarray -t -- SESSIONS <<< "$TMUX_SESSIONS"
else
  SESSIONS=()
fi

SESSION_SCRIPT='/dev/null'

if [[ -s $PLANNED_SESSION ]]; then
  SESSION_SCRIPT="$PLANNED_SESSION"
elif [[ -n $SESSION ]]; then
  # shellcheck disable=2154
  SESSION_SCRIPT="$XDG_STATE_HOME/tmux/$SESSION.sh"
elif ((${#SESSIONS[@]})); then
  if ! SESSION="$(fzf <<< "$TMUX_SESSIONS")"; then
    exit
  fi
else
  SESSION='owo'
  SESSION_SCRIPT="$XDG_STATE_HOME/tmux/$SESSION.sh"
fi

LISTED=0
for S in "${SESSIONS[@]}"; do
  if [[ $S == "$SESSION" ]]; then
    LISTED=1
    break
  fi
done

ARGV=("$LISTED" "$SESSION")
if [[ -f $SESSION_SCRIPT ]]; then
  ARGV+=("$SESSION_SCRIPT")
fi

exec -- "$XDG_CONFIG_HOME/tmux/libexec/switch-to.sh" "${ARGV[@]}"
