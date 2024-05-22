#!/usr/bin/env -S -- bash

git-use-ssh() {
  local -- remote uri
  remote="$(git remote)"
  uri="$(git remote get-url "$remote")"

  if [[ $uri =~ https://github.com ]]; then
    uri="${uri##'https://github.com/'}"
    uri="${uri%%'.git'}"
    uri="git@github.com:$uri.git"
    git remote set-url "$remote" "$uri"
  fi

  git remote get-url "$remote"
}
