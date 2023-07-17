#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

if ! [[ -v TMUX ]]; then
  exit
fi

if ! [[ -v SSH_CLIENT ]]; then
  exit
fi

DIR='/tmp/tmux-status-line'
IP="${SSH_CLIENT%% *}"
TMUX="${TMUX%%,*}"
NAME="$DIR/${TMUX//\//|}"

mkdir -p -- "$DIR"
printf -- '%s' "$IP" >"$NAME.ip2"
mv -- "$NAME.ip2" "$NAME.ip"
