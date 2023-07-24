.PHONY: git clobber.git

clobber: clobber.git

define GIT_TEMPLATE

.PHONY: clobber.git.$1
clobber.git: clobber.git.$1
clobber.git.$1:
	rm -rf -- '$1'

git: $1
$1: /usr/bin/git
	if [[ -d '$$@' ]]; then
		cd -- '$$@'
		git pull --recurse-submodules --no-tags
	else
		git clone --recurse-submodules --shallow-submodules --depth=1 -- '$2' '$$@'
	fi

endef

define GIT_REPOS

$(CONFIG)/nvim                      https://github.com/ms-jpq/nvim_rc
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

GIT_REPOS := $(shell tr -s ' ' '#' <<<'$(GIT_REPOS)')

$(call META_2D,GIT_REPOS,GIT_TEMPLATE)
