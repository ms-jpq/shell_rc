#!/usr/bin/env -S -- bash

cdt() {
  local -- tmp
  tmp="$(mktemp --directory)"
  cd -- "$tmp" || return 1

  git init --quiet
  git commit --quiet --allow-empty --allow-empty-message --no-edit --message ''
  if (($#)); then
    "$@"
  fi
}
