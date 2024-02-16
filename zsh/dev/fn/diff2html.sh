#!/usr/bin/env -S -- bash

diff2html() {
  local -- argv=("$@")
  if [[ -z "$*" ]]; then
    argv+=(--style side)
  fi
  if ! [[ -t 0 ]]; then
    argv+=(--input stdin)
  fi
  if ! [[ -t 1 ]]; then
    argv+=(--output stdout)
  fi
  npm exec --yes -- diff2html-cli "${argv[@]}"
}
