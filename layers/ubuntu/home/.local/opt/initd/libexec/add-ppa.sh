#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

hash -- curl jq gpg

# shellcheck disable=SC1091
source -- /etc/os-release gpg

PPA="$1"

DIST="${PPA%%/*}"
NAME="${PPA##*/}"

FS_NAME="ppa_${DIST}_$NAME"
GPG_FILE="/etc/apt/trusted.gpg.d/$FS_NAME.gpg"
SOURCE_FILE="/etc/apt/sources.list.d/$FS_NAME.list"

CURL=(
  curl
  --fail-with-body
  --location
  --no-progress-meter
  --
)

URI="https://api.launchpad.net/1.0/~$DIST/+archive/$NAME"
JSON="$("${CURL[@]}" "$URI")"
FINGER_PRINT="$(jq --exit-status --raw-output '.signing_key_fingerprint' <<<"$JSON")"
URI="https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x$FINGER_PRINT"
"${CURL[@]}" "$URI" | gpg --batch --dearmor --yes --output "$GPG_FILE"

# shellcheck disable=SC2154
tee -- "$SOURCE_FILE" <<-EOF
deb http://ppa.launchpad.net/$DIST/$NAME/ubuntu $VERSION_CODENAME main
EOF
