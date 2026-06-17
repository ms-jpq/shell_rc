#!/usr/bin/env -S -- bash

if [[ -v BASH_VERSION ]]; then
  _sh='bash'
else
  _sh='zsh'
fi

case "$OSTYPE" in
darwin*)
  _fzf_shell='/opt/homebrew/opt/fzf/shell'
  ;;
*)
  _fzf_shell="$HOME/.local/opt/fzf/shell"
  ;;
esac

for _fzf in "$_fzf_shell"/{key-bindings,completion}."$_sh"; do
  if [[ -r $_fzf ]]; then
    # shellcheck disable=SC1090
    source -- "$_fzf"
  fi
done
unset -- _fzf _fzf_shell

# shellcheck disable=SC2312,SC1090
source -- <(zoxide init "$_sh")
alias z=zi

# shellcheck disable=SC2154
export -- STARSHIP_CONFIG="$XDG_CONFIG_HOME/starship/starship.toml"

# shellcheck disable=SC1090,2312
source -- <(starship init "$_sh")

if [[ $_sh == zsh ]]; then
  _set_title() {
    if ! [[ -v SSH_TTY ]]; then
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
