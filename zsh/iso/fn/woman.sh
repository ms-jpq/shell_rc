#!/usr/bin/env -S -- bash

woman() {
  local -- page tmp
  tmp="$(mktemp -d)/$*.html"
  page="$(man -P tee -- "$*")"
  man2html -compress -title "MAN - $*" <<<"$page" >"$tmp"
  open "$tmp"
}
