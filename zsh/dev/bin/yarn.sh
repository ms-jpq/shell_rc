#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

# shellcheck disable=SC2154
exec -- npm exec --yes -- yarn --use-yarnrc "$XDG_CONFIG_HOME/yarn/config" "$@"
