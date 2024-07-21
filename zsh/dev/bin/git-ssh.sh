#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

SSH_KEY="$1"
shift

if ! [[ $SSH_KEY =~ '/' ]]; then
  SSH_KEY="$HOME/.ssh/$SSH_KEY"
fi

SSH=(exec ssh -o IdentitiesOnly=yes -i "$SSH_KEY" --)
SSH_KEY=$(printf -- '%q ' "${SSH[@]}")
printf -- '%s\n' "$SSH_KEY" >&2
GIT_SSH_COMMAND="$SSH_KEY" git "$@"
