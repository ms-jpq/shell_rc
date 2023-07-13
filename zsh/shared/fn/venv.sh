#!/usr/bin/env -S -- bash

venv() {
  # shellcheck disable=SC2154
  # shellcheck disable=SC1090
  source -- <(command -- "$ZDOTDIR/libexec/venv.sh" "$@")
}
