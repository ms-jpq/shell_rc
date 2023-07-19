zsh: $(BIN)/sh

$(BREW_PREFIX)/bin/dash: pkg.posix

$(BIN)/sh: $(BREW_PREFIX)/bin/dash
	ln -sf -- '$<' '$@'
