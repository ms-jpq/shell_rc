#!/usr/bin/env -S -- bash

if command -v -- bat >/dev/null; then
  bat "$@"
else
  cat "$@"
fi
