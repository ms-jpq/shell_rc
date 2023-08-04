.PHONY: zsh zsh.posix

zsh: zsh.posix

zsh.posix: $(CACHE)/zsh/dircolors.sh $(HOMEPATH)/.local/state/zsh/zz

$(CACHE)/zsh/dircolors.sh: $(OPT)/dircolors-solarized
	case "$$OSTYPE" in
	darwin*)
		DC="$$(brew --prefix)/opt/coreutils/libexec/gnubin/dircolors"
		;;
	*)
		DC='dircolors'
		;;
	esac
	TERM=xterm-256color "$$DC" --bourne-shell -- '$</dircolors.256dark' > '$@'

$(STATE)/zsh:
	mkdir -v -p -- '$@'

$(STATE)/zsh/zz: | $(STATE)/zsh
	touch -- '$@'
