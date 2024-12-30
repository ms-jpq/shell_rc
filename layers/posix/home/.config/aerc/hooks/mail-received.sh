#!/usr/bin/env -S -- bash -Eeu -o pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

# shellcheck disable=SC2154
~/.local/libexec/notify.sh "📩 $AERC_FROM_NAME" <<- EOF
$AERC_SUBJECT
EOF
