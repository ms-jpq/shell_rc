.PHONY: zsh.ubuntu

zsh: zsh.ubuntu

zsh.ubuntu: pkg.posix
	if [[ "$$SHELL" != /usr/bin/zsh ]]; then
		chsh -s '$<'
	fi
