#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

REMOTE="$(git remote)"
URI="$(git remote get-url "$REMOTE")"

case "$URI" in
'https://github.com/'*)
  URI="${URI##'https://github.com/'}"
  URI="${URI%%'.git'}"
  URI="git@github.com:$URI.git"
  git remote set-url "$REMOTE" "$URI"
  ;;
'https://gist.github.com/'*)
  URI="${URI##'https://gist.github.com/'}"
  URI="${URI##*/}"
  URI="git@github.com:$URI.git"
  git remote set-url "$REMOTE" "$URI"
  ;;
*) ;;
esac

git remote get-url "$REMOTE"
