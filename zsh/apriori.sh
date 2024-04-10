#!/usr/bin/env -S -- bash

case "$OSTYPE" in
msys)
  nt2unix() {
    local -- drive ntpath="$*"
    drive="${ntpath%%:*}"
    ntpath="${ntpath#*:}"
    # shellcheck disable=SC1003
    unixpath="/${drive,,}${ntpath//'\'/'/'}"
    printf -- '%s' "$unixpath"
  }
  ;;
*)
  nt2unix() {
    printf -- '%s' "$*"
  }
  ;;
esac
