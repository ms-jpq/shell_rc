#!/usr/bin/env -S -- bash

llf() {
  local dir="$1"
  dir="$(lf -print-last-dir)"
  if [[ -z $dir ]]; then
    return 1
  fi

  if [[ -f $dir ]]; then
    dir="$(dirname -- "$dir")"
  fi

  if [[ -d $dir ]]; then
    cd -- "$dir" || return 1
  fi
}
