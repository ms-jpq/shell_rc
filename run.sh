#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

cd -- "$(dirname -- "$0")"

export -- OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
export -- PATH="$PWD/.venv/bin:$PATH"

exec -- ansible-playbook "$@"
