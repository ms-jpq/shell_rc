.PHONY: zsh.ubuntu

zsh: zsh.ubuntu /usr/local/bin/bat /usr/local/bin/fd $(BIN)/oh-my-posh

/usr/bin/zsh /bin/batcat /bin/fdfind: | pkg.posix

/usr/local/bin/bat: | /bin/batcat
	sudo -- ln -v -sf -- '$|' '$@'

/usr/local/bin/fd: | /bin/fdfind
	sudo -- ln -v -sf -- '$|' '$@'

$(BIN)/oh-my-posh: | $(BIN)/posh-linux-$(GOARCH)
	ln -v -sf -- '$|' '$@'

ifneq ($(shell printf -- '%s' "$$SHELL"),/usr/bin/zsh)
zsh.ubuntu: /usr/bin/zsh
	sudo -- chsh -s '$<' "$$USER"
endif
