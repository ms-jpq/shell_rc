#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

UPSTREAM="$(git --no-optional-locks rev-parse --abbrev-ref --symbolic-full-name '@{upstream}')"
URI="$(git remote get-url "${UPSTREAM%%/*}")"
URI="${URI%%'.git'}/tree/${UPSTREAM#*/}"

if [[ $URI =~ ^http ]]; then
  :
elif [[ $URI =~ ^([^@]+@?)([^:]+): ]]; then
  URI="${URI##"${BASH_REMATCH[0]}"}"
  URI="$(jq --exit-status --raw-input --raw-output '[split("/")[] | @uri] | join("/")' <<< "$URI")"
  URI="https://${BASH_REMATCH[2]}/$URI"
fi

printf -- '%s\n' "$URI"
open "$URI"
