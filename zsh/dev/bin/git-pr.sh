#!/usr/bin/env -S -- bash -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

PR="$1"
REMOTE="${2:-"$(git remote)"}"

git config --worktree --replace-all -- "remote.$REMOTE.fetch" "+refs/pull/*/head:refs/remotes/$REMOTE/pull/*"
git config --worktree --add -- "remote.$REMOTE.fetch" "+refs/heads/*:refs/remotes/$REMOTE/*"
git fetch -- "$REMOTE"
git switch --create "pull/$PR" --track -- "$REMOTE/pull/$PR"
