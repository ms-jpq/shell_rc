#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

XML_SRC='https://repo.eclipse.org/content/repositories/lemminx-releases/org/eclipse/lemminx/org.eclipse.lemminx/maven-metadata.xml'
BASE_URI='https://repo.eclipse.org/content/repositories/lemminx-releases/org/eclipse/lemminx/org.eclipse.lemminx'

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

XPATH=(xmllint --xpath '//metadata/versioning/latest/text()' -)
VERSION="$("${CURL[@]}" -- "$XML_SRC" | "${XPATH[@]}")"
URI="$BASE_URI/$VERSION/org.eclipse.lemminx-$VERSION-uber.jar"

# shellcheck disable=SC2154
get.sh "$URI" | unpack.sh "$LIB"
