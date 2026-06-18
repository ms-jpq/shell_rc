#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

PANE=''
SOCKET=''

if [[ -v TMUX ]] && CTTY="$(tty 2> /dev/null < /dev/tty)"; then
  DIR="${TMUX%%,*}"
  DIR="${DIR%/*}"
  for S in "$DIR"/*; do
    if PANE="$(tmux -S "$S" list-panes -a -f "#{==:#{pane_tty},$CTTY}" -F '#{pane_id}' 2> /dev/null)" && [[ -n $PANE ]]; then
      SOCKET="$S"
      break
    fi
  done
fi

if [[ -z $SOCKET ]] && [[ -v TMUX ]] && [[ -v TMUX_PANE ]]; then
  SOCKET="${TMUX%%,*}"
  PANE="$TMUX_PANE"
fi

if [[ -z $SOCKET ]] || [[ -z $PANE ]]; then
  exit 1
fi

printf -- '%s %s' "$PANE" "$SOCKET"
