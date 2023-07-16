.PHONY: zshrc
all: zshrc

ZSH := $(shell find ./zsh)

# $(TMP)/dircolors.sh: $(TMP)/dircolors
# 	dircolors --bourne-shell -- '$</dircolors.256dark' > '$@'
# 	touch -- '$<' '$@'

define ZSH_TEMPLATE

zshrc: $$(TMP)/$(1)/home.fs/.config/zsh
$$(TMP)/$(1)/home.fs: $$(TMP)/$(1)/home.fs/.config/zsh

$$(TMP)/$(1)/home.fs/.config/zsh: ./libexec/zsh.sh $(ZSH)
	'$$<' --os $(1) --out '$$@'

endef

$(foreach os,$(OS),$(eval $(call ZSH_TEMPLATE,$(os))))
