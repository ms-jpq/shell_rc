#!/usr/bin/env -S -- bash

tz() {
  local tz
  if [[ -z "${TZ-""}" ]]; then
    case "$OSTYPE" in
    darwin*)
      tz="$(command -- sudo -- systemsetup -gettimezone)"
      TZ="${tz##* }"
      ;;
    linux*)
      :
      ;;
    msys)
      :
      ;;
    *) ;;
    esac
  fi
  printf -- '%s\n' "TZ=$TZ" >&2
}
