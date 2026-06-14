#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

SESSION="$*"

# shellcheck disable=2154
PLANNED_SESSION="$XDG_CONFIG_HOME/tmux/sessions/$SESSION.sh"

SESSION_SCRIPT='/dev/null'
if [[ -s $PLANNED_SESSION ]]; then
  SESSION_SCRIPT="$PLANNED_SESSION"
elif [[ -n $SESSION ]]; then
  # shellcheck disable=2154
  SESSION_SCRIPT="$XDG_STATE_HOME/tmux/$SESSION.sh"
elif [[ -v TMUX ]]; then
  exec -- tmux choose-tree -G -Z -s -NN
else
  SESSION='me/owo'
  SESSION_SCRIPT="$XDG_STATE_HOME/tmux/$SESSION.sh"
fi

ARGV=()
if [[ -x $SESSION_SCRIPT ]]; then
  ARGV=("$SESSION_SCRIPT")
fi

exec -- "$XDG_CONFIG_HOME/tmux/libexec/switch-to.sh" "$SESSION" "${ARGV[@]}"
