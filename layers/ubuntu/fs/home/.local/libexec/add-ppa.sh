#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

PPA="$1"

DIST="${PPA%%/*}"
NAME="${PPA##*/}"

URI="https://api.launchpad.net/1.0/~$DIST/+archive/$NAME"
JSON="$(curl --fail --location --no-progress-meter -- "$URI")"
FINGER_PRINT="$(jq --exit-status --raw-output '.signing_key_fingerprint' <<<"$JSON")"
