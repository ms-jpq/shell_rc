#!/usr/bin/env -S -- bash

sshi() {
  local -- file="$HOME/.ssh/$1"
  unshift

  local -- argv=
  if [[ "$file" = '-' ]]; then
    argv=("$@")
  else
    argv=(-o IdentitiesOnly=yes -i "$file" "$@")
  fi

  ssh "${argv[@]}"
}
