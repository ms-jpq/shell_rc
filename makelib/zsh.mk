.PHONY: zshrc

$(TMP)/dircolors: $(TMP)
	if ! [[ -d '$@' ]]; then
		git clone -- 'https://github.com/seebi/dircolors-solarized' '$@'
	fi
	touch -- '$@'

$(TMP)/dircolors.sh: $(TMP)/dircolors
	dircolors --bourne-shell -- '$</dircolors.256dark' > '$@'

$(TMP)/~/.config/zsh: ./libexec/zsh.sh $(TMP)/dircolors.sh $(shell find ./zsh)
	'$<' --os '$(OS)' --out '$@'
	cat -- '$(TMP)/dircolors.sh' >> '$@/.zshrc'

zshrc: $(TMP)/~/.config/zsh
