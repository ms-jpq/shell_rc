#!/usr/bin/env bash

set -Eeu
set -o pipefail
shopt -s globstar nullglob


cd "$(dirname -- "$0")" || exit 1

export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
export PATH="$PWD/.venv/bin:$PATH"

exec -- ansible-playbook "$@"
