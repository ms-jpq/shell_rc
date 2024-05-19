#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

PR="$1"

REMOTE="$(git remote)"
git config --local --replace-all -- "remote.$REMOTE.fetch" "+refs/pull/*/head:refs/remotes/$REMOTE/pr/*"
git config --local --add -- "remote.$REMOTE.fetch" '+refs/heads/*:refs/remotes/origin/*'
git fetch
git switch --track -- "$REMOTE/pr/$PR"
