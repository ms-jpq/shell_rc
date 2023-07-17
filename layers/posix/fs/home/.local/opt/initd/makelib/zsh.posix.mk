.PHONY: zsh zsh.posix

zsh: zsh.posix

zsh.posix: $(CACHE)/zsh/dircolors.sh $(HOME)/.local/state/zsh/zz

$(CACHE)/zsh/dircolors.sh: $(OPT)/dircolors-solarized pkg.posix
	mkdir -p -- '$(CACHE)/zsh'
	dircolors --bourne-shell -- '$</dircolors.256dark' > '$@'

$(HOME)/.local/state/zsh/zz:
	mkdir -p -- '$(HOME)/.local/state/zsh'
	touch -- '$@'
