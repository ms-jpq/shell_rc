zsh: $(BIN)/sh

/opt/homebrew/bin/dash: pkg.posix

$(BIN)/sh: /opt/homebrew/bin/dash
	ln -sf -- '$<' '$@'
