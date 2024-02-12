#!/usr/bin/env -S -- bash

# shellcheck disable=SC2154
for sh in "$XDG_DATA_HOME/zsh/aliases"/*.sh; do
  # shellcheck disable=SC1090
  source -- "$sh"
done

aliases() {
  cd -- "$XDG_DATA_HOME/zsh/aliases" || return 1
  $EDITOR
}
