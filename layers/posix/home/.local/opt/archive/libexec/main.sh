#!/usr/bin/env -S -- bash -Eeu -O dotglob -O nullglob -O extglob -O failglob -O globstar

set -o pipefail

TMP="$(mktemp -d)"
chmod -v g-rwx,o-rwx "$TMP"
gpg -v --armor --export-secret-keys --export-options export-backup --output "$TMP/gnupg.asc"
cp -v -a -r -- "$HOME/.ssh" "$TMP/ssh"
cp -v -a -r -- "$HOME/.local/share/ssh" "$TMP/ssh_hosts"
cp -v -a -r -- "$HOME/.local/share/it2" "$TMP/iterm2"
open -- "$TMP"
