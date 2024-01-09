#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

ID="$*"
DATE="$(date -Iseconds)"
# shellcheck disable=SC2154
OUT="$XDG_STATE_HOME/gnupg/$ID-$DATE.gpg"

if [[ -z "$ID" ]]; then
  set -x
  exit 1
fi

gpg --export-secret-keys --export-options export-backup --output "$OUT" -- "$ID"
gpg --list-packets -- "$OUT" >&2
printf -- '%q\n' "$OUT"
