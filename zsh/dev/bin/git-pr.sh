#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

PR="$1"

REMOTE="$(git remote)"
git config --worktree --replace-all -- "remote.$REMOTE.fetch" "+refs/pull/*:refs/remotes/$REMOTE/pull/*"
git config --worktree --add -- "remote.$REMOTE.fetch" "+refs/heads/*:refs/remotes/$REMOTE/*"
git fetch
git switch --track -- "$REMOTE/pr/$PR"
