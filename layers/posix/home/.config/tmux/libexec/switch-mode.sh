#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

SEP=$'\x1f'

RESET=$'\033[0m'
DIM=$'\033[2m'
BLUE=$'\033[34m'
GREEN=$'\033[32m'
MAGENTA=$'\033[35m'

case "${RECUR:-}" in
list)
  FORMAT=(
    '#{session_id}:#{window_id}.#{pane_id}'
    "$BLUE#{session_name}$RESET"
    "$DIM#{window_index}.#{pane_index}$RESET"
    "$MAGENTA#{window_name}$RESET"
    "$GREEN#{pane_current_command}$RESET"
    "$DIM"'#{s|^#{HOME}$|~|;s|^#{HOME}/|~/|:pane_current_path}'"$RESET"
    '#{pane_title}'
  )
  IFS="$SEP"
  LINE="${FORMAT[*]}"
  exec -- tmux list-panes -a -F "${LINE//"$SEP"/"$SEP "}"
  ;;
'')
  LIST=(env -- RECUR=list "$0")
  PANES="$("${LIST[@]}")"
  if [[ -z $PANES ]]; then
    exit
  fi
  FZF=(
    fzf
    --ansi
    --extended
    --no-exact
    --smart-case
    --literal
    --no-multi
    --no-border
    --delimiter "$SEP "
    --with-nth '2..'
    --nth '1,3..'
    --query "$*"
    --preview 'tmux capture-pane -e -p -t {1}'
    --preview-window 'right,65%,nowrap'
    --bind "ctrl-r:reload(${LIST[*]@Q})"
    --bind 'ctrl-/:toggle-preview'
    --bind 'alt-e:ignore,alt-o:ignore'
  )
  if SELECTED="$("${FZF[@]}" <<< "$PANES")"; then
    TARGET="${SELECTED%%"$SEP"*}"
  else
    CODE="$?"
    case "$CODE" in
    1 | 130) exit ;;
    *) exit "$CODE" ;;
    esac
  fi
  if [[ -n ${TMUX:-} ]]; then
    exec -- tmux switch-client -t "$TARGET"
  else
    exec -- tmux attach-session -t "$TARGET"
  fi
  ;;
*)
  set -x
  exit 2
  ;;
esac
