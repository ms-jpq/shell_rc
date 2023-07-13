.PHONY: zshrc
all: zshrc

ZSH := $(shell find ./zsh)

$(TMP)/dircolors: $(TMP)
	if [[ -d '$@' ]]; then
		cd -- '$@'
		git pull --force
	else
		git clone -- 'https://github.com/seebi/dircolors-solarized' '$@'
	fi
	touch -- '$@'

$(TMP)/dircolors.sh: $(TMP)/dircolors
	dircolors --bourne-shell -- '$</dircolors.256dark' > '$@'
	touch -- '$<' '$@'

define ZSH_TEMPLATE

zshrc: $$(TMP)/$(1)/home.fs/.config/zsh

$$(TMP)/$(1)/home.fs/.config/zsh: ./libexec/zsh.sh $(TMP)/dircolors.sh $(ZSH)
	'$$<' --os $(1) --out '$$@'
	cat -- '$(TMP)/dircolors.sh' >> '$$@/.zshrc'
	touch -- '$(TMP)/dircolors' '$(TMP)/dircolors.sh' '$$@'

endef

$(foreach os,$(OS),$(eval $(call ZSH_TEMPLATE,$(os))))

zshrc:
	touch -- '$(TMP)/dircolors' '$(TMP)/dircolors.sh' $^
