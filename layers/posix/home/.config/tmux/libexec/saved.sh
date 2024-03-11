#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

if ! [[ -v TMUX_SAVED ]]; then
  TMUX_SAVED=1 exec -- flock --conflict-exit-code 0 --nonblock "$0" "$0" "$@"
fi

while true; do
  sleep -- 1
  if "${0%/*}/save.sh" "$@"; then
    :
  fi
done
