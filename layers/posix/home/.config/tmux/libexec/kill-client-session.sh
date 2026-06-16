#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

CLIENT="$1"

SESSION="$(tmux list-clients -F '#{client_session}' -f "#{==:#{client_name},$CLIENT}")"

if [[ -n $SESSION ]]; then
  exec -- tmux kill-session -t "=$SESSION"
fi
