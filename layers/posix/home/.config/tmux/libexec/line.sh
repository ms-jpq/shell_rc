#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

cd -- "${0%/*}/.."

# shellcheck disable=SC2154
PY="$XDG_DATA_HOME/tmux/bin/python3"
if ! [[ -x "$PY" ]]; then
  PY="$(command -v -- python3)"
fi
exec -- "$PY" -m libexec "$@"
