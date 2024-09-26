#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

# shellcheck disable=SC1091
source -- /etc/os-release

SWIFT_VERSION='6.0.1'
# shellcheck disable=SC2154
URI="https://download.swift.org/swift-$SWIFT_VERSION-release/$ID${VERSION_ID//./}/swift-$SWIFT_VERSION-RELEASE/swift-$SWIFT_VERSION-RELEASE-$ID$VERSION_ID.tar.gz"

SWIFTS_HOME=~/".local/opt/swift"
SWIFT_HOME="$SWIFTS_HOME/$SWIFT_VERSION"
rm -v -fr -- "$SWIFT_HOME"
mkdir -v -p -- "$SWIFT_HOME"
curl --location --fail-with-body --no-progress-meter -- "$URI" | tar -v --extract --gzip --directory "$SWIFT_HOME" --strip-components 1
ln -sf -- "$SWIFT_HOME" "$SWIFTS_HOME/current"
