.PHONY: zsh.ubuntu

zsh: zsh.ubuntu

/usr/bin/zsh: pkg.posix

zsh.ubuntu: /usr/bin/zsh
	if [[ "$$SHELL" != '$<' ]]; then
		chsh -s '$<'
	fi
