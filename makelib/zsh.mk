.PHONY: zshrc
all: zshrc

ZSH := $(shell printf -- '%s ' ./zsh/**/*)

define ZSH_TEMPLATE

zshrc: $(TMP)/$1/home/.config/zsh
$(TMP)/$1/home: $(TMP)/$1/home/.config/zsh

$(TMP)/$1/home/.config/zsh: ./libexec/zsh.sh $(ZSH)
	'$$<' $1 '$$@'

endef

$(foreach os,$(GOOS),$(eval $(call ZSH_TEMPLATE,$(os))))
