#!/usr/bin/env -S -- bash

# shellcheck disable=SC2154
if [[ -v XDG_RUNTIME_DIR ]]; then
  export -- SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/gnupg/S.gpg-agent.ssh"
else
  export -- GNUPGHOME="$XDG_CONFIG_HOME/gnupg"
  export -- SSH_AUTH_SOCK="$GNUPGHOME/S.gpg-agent.ssh"
fi
