#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

if ! [[ -v TMUX ]] && ! [[ -v TMUX_ROOT ]]; then
  exec -- "$@"
fi

TM=(tmux -S "${TMUX_ROOT:-${TMUX%%,*}}")
T=(-t "${TMUX_ROOT_PANE:-${TMUX_PANE:-}}")

PANES="$("${TM[@]}" display-message "${T[@]}" -p -- '#{window_panes}')"
if ((PANES == 1)); then
  ARGV=("${TM[@]}" split-window -h "${T[@]}")
else
  W="$("${TM[@]}" display-message "${T[@]}" -p -- '#{window_id}')"
  ARGV=("${TM[@]}" new-window -a -t "$W")
fi

ARGV+=(-P -F '#{pane_id}')
if ! tty 2> /dev/null < /dev/tty > /dev/null; then
  ARGV+=(-d)
fi

if [[ -d $* ]]; then
  ARGV+=(-c "$*")
  PANE="$("${ARGV[@]}")"
else
  ARGV+=(-c '#{pane_current_path}')
  PANE="$("${ARGV[@]}" -- "$@")"
fi

exec -- "$HOME/.config/tmux/libexec/taint-inactive.sh" "$PANE"
