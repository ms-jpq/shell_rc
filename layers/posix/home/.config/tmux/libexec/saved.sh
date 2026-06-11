#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

LOCK="/tmp/tmux-saved.$UID.lock"

if ! [[ -v TMUX_SAVED ]]; then
  if ! mkdir -- "$LOCK" 2> /dev/null; then
    exit 0
  fi
  TMUX_SAVED=1 exec -- "$0" "$@"
fi

trap 'exit' INT TERM HUP
trap 'rmdir -- "$LOCK" 2> /dev/null || true' EXIT

while true; do
  sleep -- 1
  if "${0%/*}/save.sh" "$@"; then
    :
  fi
done
