#!/usr/bin/env -S -- bash

git-hub() {
  local -- upstream uri
  upstream="$(git --no-optional-locks rev-parse --abbrev-ref --symbolic-full-name '@{upstream}')"
  uri="$(git remote get-url "${upstream%%/*}")"

  if [[ "$uri" =~ git@github.com: ]]; then
    uri="${uri##'git@github.com:'}"
  fi
  uri="${uri%%'.git'}/tree/${upstream#*/}"
  uri="$(jq --exit-status --raw-input --raw-output '[split("/")[] | @uri] | join("/")' <<<"$uri")"
  if ! [[ "$uri" =~ ^http ]]; then
    uri="https://github.com/$uri"
  fi

  printf -- '%s\n' "$uri"
  open "$uri"
}
