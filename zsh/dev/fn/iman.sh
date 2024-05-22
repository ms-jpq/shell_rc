#!/usr/bin/env -S -- bash

iman() {
  local q="$*"
  q="$(jq --exit-status --raw-input --raw-output <<< "$q")"
  open -- "https://manpages.ubuntu.com/cgi-bin/search.py?q=$q"
}
