#!/usr/bin/env -S -- bash

path=("$HOME/.local/lbin" "$HOME/.local/bin" "${path[@]}")

if ((SHLVL > 1)); then
  declare -A -- _seen
  _pacc=()
  for _p in "${path[@]}"; do
    if [[ -z ${_seen["$_p"]} ]]; then
      _seen["$_p"]=1
      _pacc+=("$_p")
    fi
  done
  path=("${_pacc[@]}")
  unset -- _seen _pacc _p
fi
