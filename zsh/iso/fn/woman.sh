#!/usr/bin/env -S -- bash

woman() {
  local -- tmp pr m2
  m2="$(command -v -- man2html)"
  tmp="$(mktemp -d)/index.html"
  pr="$(printf -- '%q ' perl -CASD "$m2" -compress -title "MAN - $*")"
  man -P "$pr" -- "$*" </dev/null >"$tmp"
  open "$tmp"
}
