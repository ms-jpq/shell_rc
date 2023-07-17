.PHONY: zsh.ubuntu

zsh: zsh.ubuntu /usr/local/bin/bat /usr/local/bin/fd $(BIN)/oh-my-posh

/usr/bin/zsh /bin/batcat /bin/fdfind: pkg.posix

/usr/local/bin/bat: /bin/batcat
	sudo -- ln -sf -- '$<' '$@'

/usr/local/bin/fd: /bin/fdfind
	sudo -- ln -sf -- '$<' '$@'

$(BIN)/oh-my-posh: $(BIN)/posh-linux-$(GOARCH)
	sudo -- ln -sf -- '$<' '$@'

zsh.ubuntu: /usr/bin/zsh
	if [[ "$$SHELL" != '$<' ]]; then
		chsh -s '$<'
	fi
