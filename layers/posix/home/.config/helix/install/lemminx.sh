#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

BASE_URI='https://download.jboss.org/jbosstools/vscode/stable/lemminx-binary'

EXT=''
case "$OSTYPE" in
darwin*)
  BASENAME='lemminx-osx-x86_64.zip'
  ;;
linux*)
  BASENAME='lemminx-linux.zip'
  ;;
*)
  BASENAME='lemminx-win32.zip'
  EXT='.exe'
  ;;
esac

CURL=(curl --fail-with-body --location --no-progress-meter --max-time 600 -- "$BASE_URI")
XPATH=(xmllint --html --xpath '(//html/body/table/tr/td/a/text())[last()]' -)
VERSION="$("${CURL[@]}" | "${XPATH[@]}")"
URI="$BASE_URI/$VERSION$BASENAME"
# shellcheck disable=SC2154
get.sh "$URI" | unpack.sh "$TMP"
# shellcheck disable=SC2154
mv -v -f -- "$TMP/lemminx"* "$BIN/lemminx$EXT"
