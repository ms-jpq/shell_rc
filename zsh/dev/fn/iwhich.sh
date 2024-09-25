#!/usr/bin/env -S -- bash

iwhich() {
  local URI="https://command-not-found.com/$*"
  printf -- '%s\n' "$URI"
  open -- "$URI"
}
