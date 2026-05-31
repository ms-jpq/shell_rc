#!/usr/bin/env -S -- bash

for _sh in ~/.local/lprofile.d/*.sh; do
  # shellcheck disable=SC1090
  source -- "$_sh"
done

if [[ -v BASH_VERSION ]]; then
  _sh='bash'
else
  _sh='zsh'
fi

# shellcheck disable=SC2154
_posh_conf="$XDG_CONFIG_HOME/posh/config.yml"

# shellcheck disable=SC1090,2312
source -- <(oh-my-posh init "$_sh" --config "$_posh_conf")

unset -- _sh _posh_conf
