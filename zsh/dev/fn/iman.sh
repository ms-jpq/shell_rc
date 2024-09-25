#!/usr/bin/env -S -- bash

iman() {
  local q="$*"
  q="$(jq --exit-status --raw-input --raw-output <<< "$q")"
  q="https://manpages.ubuntu.com/cgi-bin/search.py?q=$q"
  printf -- '%s\n' "$q"
  open -- "$q"
}
