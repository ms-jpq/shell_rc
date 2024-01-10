#!/bin/bash

set -Eeu
set -o pipefail

BIN='/opt/homebrew/bin'
PATH="$BIN:$PATH"

export -- GNUPGHOME="$HOME/.config/gnupg"

ARGV=(
  gpg-agent
  --log-file "$HOME/.local/state/gnupg/agent.log"
  --daemon "$HOME/.config/gnupg/libexec/sleep.sh"
)

exec -- "${ARGV[@]}" </dev/null
