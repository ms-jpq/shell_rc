.PHONY: zsh.ubuntu

zsh: zsh.ubuntu /usr/local/bin/bat /usr/local/bin/fd

/usr/bin/zsh /bin/batcat /bin/fdfind: | pkg.posix

/usr/local/bin/bat: | /bin/batcat
	sudo -- ln -v -snf -- '$|' '$@'

/usr/local/bin/fd: | /bin/fdfind
	sudo -- ln -v -snf -- '$|' '$@'

ifneq ($(shell printf -- '%s' "$$SHELL"),/usr/bin/zsh)
zsh.ubuntu: /usr/bin/zsh
	USER="$${USER:-"$$(whoami)"}"
	sudo -- chsh -s '$<' "$$USER"
endif
