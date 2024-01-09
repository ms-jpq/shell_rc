#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

ID="$*"

if [[ -z "$ID" ]]; then
  set -x
  gpg --list-keys --with-subkey-fingerprints >&2
  exit 1
else
  gpg --armor --export-secret-keys -- "$ID"
fi
