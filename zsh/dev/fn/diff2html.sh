#!/usr/bin/env -S -- bash

diff2html() {
  local -- argv=("$@")
  if ! ((${#argv[@]})); then
    argv+=(--input stdin)
  fi
  npm exec --yes -- diff2html-cli "${argv[@]}"
}
