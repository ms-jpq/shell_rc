.PHONY: git clobber.git

clobber: clobber.git

define GIT_TEMPLATE

.PHONY: clobber.git.$(notdir $1)
clobber.git: clobber.git.$(notdir $1)
clobber.git.$(notdir $1):
	rm -v -rf -- '$(call UNIX_2_NT,$1)'

git: $1
$1: | $(CONFIG)/git/config
	if [[ -d '$$@' ]]; then
		git -C '$$@' pull --recurse-submodules --no-tags '--jobs=$(NPROC)'
	else
		git clone --recurse-submodules --shallow-submodules --depth=1 '--jobs=$(NPROC)' -- '$2' '$$@'
	fi

endef

define GIT_REPOS

$(CONFIG)/nvim                 https://github.com/ms-jpq/nvim_rc
$(OPT)/ai                      https://github.com/ms-jpq/ai
$(OPT)/asdf                    https://github.com/asdf-vm/asdf
$(OPT)/fzf-tab                 https://github.com/Aloxaf/fzf-tab
$(OPT)/isomorphic-copy         https://github.com/ms-jpq/isomorphic-copy
$(OPT)/pipes.sh                https://github.com/pipeseroni/pipes.sh
$(OPT)/zsh-autosuggestions     https://github.com/zsh-users/zsh-autosuggestions
$(OPT)/zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting

endef

GIT_REPOS := $(shell tr -s -- ' ' '!' <<<'$(GIT_REPOS)')

$(call META_2D,GIT_REPOS,GIT_TEMPLATE)
