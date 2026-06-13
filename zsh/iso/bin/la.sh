#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

LC_ALL=en_US.UTF-8 exec -- lazygit "$@"
