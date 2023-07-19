#!/usr/bin/env -S -- bash

git-ssh() {
  local -- ssh_key ssh
  ssh_key="$1"
  shift

  if ! [[ "$ssh_key" =~ '/' ]]; then
    ssh_key="$HOME/.ssh/$ssh_key"
  fi

  ssh=(ssh -o IdentitiesOnly=yes -i "$ssh_key")
  ssh_key=$(printf -- '%q ' "${ssh[@]}")
  printf -- '%s\n' "$ssh_key"
  GIT_SSH_COMMAND="$ssh_key" command -- git "$@"
}
