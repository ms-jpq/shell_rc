#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

if ! [[ -v TMUX ]] && ! [[ -v __TMUX_ROOT_SOCKET__ ]]; then
  exec -- "$@"
fi

SOCKET="${__TMUX_ROOT_SOCKET__:-${TMUX%%,*}}"
TM=(tmux -S "$SOCKET")
T=(-t "${__TMUX_ROOT_PANE__:-${TMUX_PANE:-}}")

PANES="$("${TM[@]}" display-message "${T[@]}" -p -- '#{window_panes}')"
ZOOMED="$("${TM[@]}" display-message "${T[@]}" -p -- '#{window_zoomed_flag}')"
if ((PANES == 1)); then
  ARGV=("${TM[@]}" split-window -h "${T[@]}")
else
  W="$("${TM[@]}" display-message "${T[@]}" -p -- '#{window_id}')"
  ARGV=("${TM[@]}" new-window -a -t "$W")
fi

ARGV+=(-P -F '#{pane_id}')
if ((ZOOMED)) || ! tty 2> /dev/null < /dev/tty > /dev/null; then
  ARGV+=(-d)
fi

if [[ -d $* ]]; then
  ARGV+=(-c "$*")
  PANE="$("${ARGV[@]}")"
else
  ARGV+=(-c '#{pane_current_path}')
  PANE="$("${ARGV[@]}" -- "$@")"
fi

exec -- "$HOME/.config/tmux/libexec/taint-inactive.sh" "$PANE" "$SOCKET"
