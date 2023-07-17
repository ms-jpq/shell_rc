.PHONY: zsh zsh.posix

zsh: zsh.posix

zsh.posix: $(HOME)/.cache/zsh/dircolors.sh $(HOME)/.local/state/zsh/zz

$(HOME)/.cache/zsh/dircolors.sh: $(OPT)/dircolors-solarized pkg.posix
	mkdir -p -- '$(HOME)/.cache/zsh'
	dircolors --bourne-shell -- '$</dircolors.256dark' > '$@'

$(HOME)/.local/state/zsh/zz:
	mkdir -p -- '$(HOME)/.local/state/zsh'
	touch -- '$@'
