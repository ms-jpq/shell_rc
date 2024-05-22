#!/usr/bin/env -S -- bash

path=("$HOME/.local/lbin" "$HOME/.local/bin" "${path[@]}")

if ((SHLVL > 1)); then
  declare -A -- seen
  pacc=()
  for p in "${path[@]}"; do
    if [[ -z ${seen["$p"]} ]]; then
      seen["$p"]=1
      pacc+=("$p")
    fi
  done
  path=("${pacc[@]}")
  unset -- seen pacc
fi
