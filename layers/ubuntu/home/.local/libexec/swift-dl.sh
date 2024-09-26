#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

# shellcheck disable=SC1091
source -- /etc/os-release

SWIFT_VERSION='swift-6.0.1-RELEASE'
SWIFT_V="${SWIFT_VERSION//'-RELEASE'/'-release'}"

SWIFTS_HOME=~/".local/opt/swift"
SWIFT_HOME="$SWIFTS_HOME/$SWIFT_VERSION"
TMP="$SWIFT_HOME.tmp"

# shellcheck disable=SC2154
TOOLCHAIN="https://download.swift.org/$SWIFT_V/$ID${VERSION_ID//./}/$SWIFT_VERSION/$SWIFT_VERSION-$ID$VERSION_ID.tar.gz"
STATIC_SDK="https://download.swift.org/$SWIFT_V/static-sdk/$SWIFT_VERSION/${SWIFT_VERSION}_static-linux-0.0.1.artifactbundle.tar.gz"
printf -- '%s\n' "$TOOLCHAIN" "$STATIC_SDK" >&2

CURL=(curl --no-progress-meter --location --fail-with-body --url "$TOOLCHAIN" --next --location --fail-with-body --url "$STATIC_SDK")
TAR=(tar -v --extract --ignore-zeros --gzip --directory "$TMP" --strip-components 1)

rm -v -fr -- "$TMP"
mkdir -v -p -- "$TMP"
"${CURL[@]}" | "${TAR[@]}"

rm -v -fr -- "$SWIFT_HOME"
mv -v -f -- "$TMP" "$SWIFT_HOME"
ln -snf -- "$SWIFT_HOME" "$SWIFTS_HOME/current"
