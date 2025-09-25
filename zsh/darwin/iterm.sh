#!/usr/bin/env -S -- bash

if [[ -f  ~/.iterm2_shell_integration.zsh ]]; then
  export -- ITERM_ENABLE_SHELL_INTEGRATION_WITH_TMUX=1
  source -- ~/.iterm2_shell_integration.zsh
fi
