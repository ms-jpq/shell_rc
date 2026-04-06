#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

TOP="$(git --no-optional-locks rev-parse --path-format=absolute --show-toplevel || printf -- '%s' "$PWD")"

realpath --no-symlinks --relative-to "$TOP" -- "$@" | sed -E -z -e 's/\n$//' | ~/.config/zsh/bin/c
