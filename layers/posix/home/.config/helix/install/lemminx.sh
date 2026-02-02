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

if ! command -v -- xmllint > /dev/null; then
  set -x
  exit 0
fi

CURL=(curl --fail --location --no-progress-meter --max-time 600)
if [[ -v IPV4 ]]; then
  CURL+=(-4)
elif [[ -v IPV6 ]]; then
  CURL+=(-6)
fi
CURL+=(-- "$BASE_URI")

XPATH=(xmllint --html --xpath '(//html/body/table/tr/td/a/text())[last()]' -)
VERSION="$("${CURL[@]}" | "${XPATH[@]}")"
URI="$BASE_URI/$VERSION$BASENAME"
# shellcheck disable=SC2154
get.sh "$URI" | unpack.sh "$RUN"
# shellcheck disable=SC2154
mkdir -p -- "$BIN"
mv -v -f -- "$RUN/lemminx"* "$BIN/lemminx$EXT"
