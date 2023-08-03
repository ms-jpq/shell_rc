#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

if command -v -- pwsh >/dev/null; then
  PSH='pwsh'
elif command -v -- powershell >/dev/null; then
  PSH='powershell'
else
  exit 127
fi

"$PSH" -nologo -noprofile -command "$*"
