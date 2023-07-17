.PHONY: zsh zsh.posix

zsh: zsh.posix

zsh.posix: $(HOME)/.cache/zsh/dircolors.sh

$(HOME)/.cache/zsh/dircolors.sh: $(OPT)/dircolors-solarized pkg.posix
	mkdir -p -- '$(HOME)/.cache/zsh'
	dircolors --bourne-shell -- '$</dircolors.256dark' > '$@'
