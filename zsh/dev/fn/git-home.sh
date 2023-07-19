#!/usr/bin/env -S -- bash

git-home() {
  local -- top
  top="$(git --no-optional-locks rev-parse --show-toplevel)"
  cd -- "$top" || return 1
}
