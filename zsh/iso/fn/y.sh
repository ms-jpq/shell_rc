#!/usr/bin/env -S -- bash

function y() {
  local f d
  f="$(mktemp)"
  yazi --cwd-file "$f"
  d="$(< "$f")"
  command -- rm -fr -- "$f"
  builtin cd -- "$d" || return 1
}
