#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

bsdtar --no-mac-metadata --list -z --file - | tree --fromfile -F -C
