.PHONY: zshrc
all: zshrc

ZSH := $(shell find ./zsh)

define ZSH_TEMPLATE

zshrc: $$(TMP)/$(1)/home.fs/.config/zsh
$$(TMP)/$(1)/home.fs: $$(TMP)/$(1)/home.fs/.config/zsh

$$(TMP)/$(1)/home.fs/.config/zsh: ./libexec/zsh.sh $(ZSH)
	'$$<' $(1) '$$@'

endef

$(foreach os,$(OS),$(eval $(call ZSH_TEMPLATE,$(os))))
