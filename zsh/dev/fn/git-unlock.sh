#!/usr/bin/env -S -- bash

git-unlock() {
  local -- dir
  dir="$(git --no-optional-locks rev-parse --git-dir)"
  rm -v -f -- "$dir/index.lock"
}
