#!/usr/bin/env -S -- bash

sshi() {
  local -- file="$HOME/.ssh/$1"
  unshift -- 1

  local -- argv=
  if [[ $file == '-' ]]; then
    argv=("$@")
  else
    argv=(-o IdentitiesOnly=yes -i "$file" "$@")
  fi

  ssh "${argv[@]}"
}
