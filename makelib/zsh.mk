.PHONY: zsh

./tmp/dircolors: ./tmp
	if ! [[ -d '$@' ]]; then
		git clone -- 'https://github.com/seebi/dircolors-solarized' '$@'
	fi
	touch -- '$@'

./tmp/dircolors.sh: ./tmp/dircolors
	dircolors --bourne-shell -- '$</dircolors.256dark' > '$@'

# $(TMP)/~/.config/zsh: $(TMP)
# 	mkdir -p -- '$@'

# $(TMP)/~/.cache: $(TMP)/~
# 	ln -sf -- '$(CURDIR)/zshrc' '$@'

