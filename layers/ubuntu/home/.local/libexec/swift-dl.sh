#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

SWIFT_VERSION='swift-6.0.1-RELEASE'
SDK_V='0.0.1'

if [[ -v RECURSION ]]; then
  TMP="$1"
  DST="${TMP%'.tmp'}"
  CURL=(
    curl
    --location
    --fail-with-body
    --no-progress-meter
    -- "$2"
  )
  TAR=(
    tar
    --extract
    --gzip
    --directory "$TMP"
    --strip-components 1
  )

  rm -fr -- "$TMP"
  mkdir -p -- "$TMP"

  "${CURL[@]}" | "${TAR[@]}"
  rm -fr -- "$DST"
  exec -- mv -v -f -- "$TMP" "$DST"
else
  LINK_HOME=~/.config/swiftpm/swift-sdks
  SWIFTS_HOME=~/".local/opt/swift"
  TOOLS_HOME="$SWIFTS_HOME/tools"
  SDKS_HOME="$SWIFTS_HOME/sdk"

  SWIFT_V="${SWIFT_VERSION//'-RELEASE'/'-release'}"

  # shellcheck disable=SC1091
  source -- /etc/os-release
  # shellcheck disable=SC2154
  TOOLCHAIN="https://download.swift.org/$SWIFT_V/$ID${VERSION_ID//./}/$SWIFT_VERSION/$SWIFT_VERSION-$ID$VERSION_ID.tar.gz"
  STATIC_SDK="https://download.swift.org/$SWIFT_V/static-sdk/$SWIFT_VERSION/${SWIFT_VERSION}_static-linux-$SDK_V.artifactbundle.tar.gz"
  SDK_VERSION="${STATIC_SDK##*/}"
  SDK_VERSION="${SDK_VERSION%'.tar.gz'}"

  TOOL_HOME="$TOOLS_HOME/$SWIFT_VERSION"

  ARGV=(
    "$TOOL_HOME.tmp" "$TOOLCHAIN"
    "$SDKS_HOME/$SDK_VERSION.tmp" "$STATIC_SDK"
  )

  printf -- '%s\0' "${ARGV[@]}" | RECURSION=1 xargs --no-run-if-empty --null --max-args 2 --max-procs 0 -- "$0"
  ln -snf -- "$TOOL_HOME" "$TOOLS_HOME/current"
  mkdir -v -p -- "$LINK_HOME"
  find "$LINK_HOME" -mindepth 1 -maxdepth 1 -delete
  find "$SDKS_HOME" -mindepth 1 -maxdepth 1 -execdir ln -snf -- "$SDKS_HOME/{}" "$LINK_HOME/{}" ';'
fi
