.PHONY: git

define GIT_TEMPLATE
git: $(1)
$(1):
	if [[ -d '$(1)' ]]; then
		cd -- '$(1)'
		git pull --recurse-submodules --no-tags
	else
		git clone --recurse-submodules --shallow-submodules --depth=1 -- '$(2)' '$(1)'
	fi
endef

define GIT_REPOS
$(CONFIG)/nvim                      https://github.com/ms-jpq/nvim_rc
$(CONFIG)/tmux                      https://github.com/ms-jpq/tmux_rc
$(OPT)/asdf                         https://github.com/asdf-vm/asdf
$(OPT)/dircolors-solarized          https://github.com/seebi/dircolors-solarized
$(OPT)/fzf                          https://github.com/junegunn/fzf
$(OPT)/fzf-tab                      https://github.com/Aloxaf/fzf-tab
$(OPT)/isomorphic-copy              https://github.com/ms-jpq/isomorphic-copy
$(OPT)/z                            https://github.com/rupa/z
$(OPT)/zsh-autosuggestions          https://github.com/zsh-users/zsh-autosuggestions
$(OPT)/zsh-history-substring-search https://github.com/zsh-users/zsh-history-substring-search
$(OPT)/zsh-syntax-highlighting      https://github.com/zsh-users/zsh-syntax-highlighting
endef

GIT_REPOS := $(shell sed 's/[[:space:]]\+/#/' <<<'$(GIT_REPOS)')

$(foreach repo,$(GIT_REPOS),$(eval $(call GIT_TEMPLATE,$(firstword $(subst #, ,$(repo))),$(lastword $(subst #, ,$(repo))))))
