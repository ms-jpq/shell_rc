#!/usr/bin/env -S -- bash

woman() {
  local -- page tmp pr m2
  m2="$(command -v -- man2html)"
  tmp="$(mktemp -d)/index.html"
  pr="$(printf -- '%q ' pr -e$'\n2')"
  page="$(man -P "$pr" -- "$*")"
  perl -CASD "$m2" -compress -title "MAN - $*" <<<"$page" >"$tmp"
  open "$tmp"
}
