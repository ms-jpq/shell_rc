#!/usr/bin/env -S -- bash

if [[ -n ${BASH_VERSION:-} ]]; then
  _sh='bash'
else
  _sh='zsh'
fi

# shellcheck disable=SC2154
_fzf="$XDG_CACHE_HOME/fzf/integration.$_sh"
if [[ -r $_fzf ]]; then
  # shellcheck disable=SC1090
  source -- "$_fzf"
fi
unset -- _fzf

# shellcheck disable=SC2312,SC1090
source -- <(zoxide init "$_sh")
alias z=zi

# shellcheck disable=SC2154
export -- STARSHIP_CONFIG="$XDG_CONFIG_HOME/starship/starship.toml"

# shellcheck disable=SC1090,2312
source -- <(starship init "$_sh")

if [[ $_sh == zsh ]]; then
  # https://github.com/starship/starship/issues/7289
  # shellcheck disable=SC2034
  ZLE_RPROMPT_INDENT=0

  _set_title() {
    if [[ -z ${SSH_TTY:-} ]]; then
      if [[ $PWD == "$HOME" ]]; then
        # shellcheck disable=SC2088
        title '~/'
      else
        title "${PWD##*/}"
      fi
    fi
  }
  add-zsh-hook -- precmd _set_title
fi

unset -- _sh

for _sh in ~/.local/lprofile.d/*.sh; do
  # shellcheck disable=SC1090
  source -- "$_sh"
done
