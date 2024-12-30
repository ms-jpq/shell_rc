#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

ARGV=(mbsync)

if (($#)); then
  ARGV+=("$@")
else
  ARGV+=(--all)
fi

OPT='/opt/homebrew/opt'
SASL_PATH="$OPT/cyrus-sasl/lib/sasl2:$OPT/cyrus-sasl-xoauth2/lib/sasl2" exec -- "${ARGV[@]}"
