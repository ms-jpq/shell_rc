.PHONY: zshrc
all: zshrc

ZSH := ./layers/posix/home/.zshenv $(shell find ./zsh -type f)

define ZSH_TEMPLATE

zshrc: $(TMP)/$1/rc/.config/zsh/.zshrc $(TMP)/$1/rc/.bashrc

$(TMP)/$1/rc/.config/zsh/.zshrc: ./libexec/zsh.sh $(ZSH)
	'$$<' '$1' '$(TMP)/$1/rc/.config/zsh' '$(TMP)/$1/rc'

$(TMP)/$1/rc/.bashrc: $(TMP)/$1/rc/.config/zsh/.zshrc

endef

$(foreach os,$(GOOS),$(eval $(call ZSH_TEMPLATE,$(os))))
