.PHONY: zshrc

ZSH := $(shell find ./zsh)

$(TMP)/dircolors: $(TMP)
	git clone -- 'https://github.com/seebi/dircolors-solarized' '$@'

$(TMP)/dircolors.sh: $(TMP)/dircolors
	dircolors --bourne-shell -- '$</dircolors.256dark' > '$@'
	touch -- '$<' '$@'

define ZSH_TEMPLATE

zshrc: $$(TMP)/$(1)/zsh
$$(TMP)/$(1)/zsh: ./libexec/zsh.sh ./tmp/dircolors.sh $(ZSH)
	'$$<' --os $(1) --out '$$@'
	cat -- '$(TMP)/dircolors.sh' >> '$$@/.zshrc'
	touch -- '$(TMP)/dircolors' '$(TMP)/dircolors.sh' '$$@'

endef

$(foreach os,$(OS),$(eval $(call ZSH_TEMPLATE,$(os))))

zshrc:
	touch -- '$(TMP)/dircolors' '$(TMP)/dircolors.sh' $^
