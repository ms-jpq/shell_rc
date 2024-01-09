#!/usr/bin/env -S -- bash

# shellcheck disable=SC2154
export -- GNUPGHOME="$XDG_CONFIG_HOME/gnupg"
export -- SSH_AUTH_SOCK="$GNUPGHOME/S.gpg-agent.ssh"
