#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

cd -- "${0%/*}/.."

# shellcheck disable=SC2154
"$XDG_DATA_HOME/tmux/bin/python3" -m libexec "$@"
