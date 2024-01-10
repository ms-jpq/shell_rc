#!/bin/bash

set -Eeu
set -o pipefail

ARGV=(
  gpg-agent
  --log-file "$HOME/.local/state/gnupg/agent.log"
  --daemon "$HOME/.config/gnupg/libexec/sleep.sh"
)

PATH="/opt/homebrew/bin:$PATH" GNUPGHOME="$HOME/.config/gnupg" exec -- "${ARGV[@]}"
