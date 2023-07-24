#!/usr/bin/env -S -- bash

# shellcheck disable=SC2046
dun() {
  local ps
  # shellcheck disable=SC2207
  ps=($(docker ps --all --quiet))
  if [[ -n "${ps[*]}" ]]; then
    docker rm --force -- "${ps[@]}"
  fi
}
