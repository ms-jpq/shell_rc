#!/usr/bin/env -S -- bash

# shellcheck disable=SC1090
source -- /dev/null ~/.local/lprofile.d/*.sh

_sh="${SHELL##*/}"

# shellcheck disable=SC2154
_posh_conf="$XDG_CONFIG_HOME/posh/config.yml"
# shellcheck disable=SC2154
_posh_cache="$XDG_CACHE_HOME/oh-my-posh/init.dog.$_sh"

# shellcheck disable=SC2312
if [[ ! -s $_posh_cache || $_posh_conf -nt $_posh_cache || $(command -v -- oh-my-posh) -nt $_posh_cache ]]; then
  oh-my-posh init "$_sh" --config "$_posh_conf" > "$_posh_cache"
fi

# shellcheck disable=SC2312
source -- "$_posh_cache"

unset -- _sh _posh_conf _posh_cache
