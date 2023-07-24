.PHONY: zsh zsh.posix

zsh: zsh.posix

zsh.posix: $(CACHE)/zsh/dircolors.sh $(HOME)/.local/state/zsh/zz

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

$(HOME)/.local/state/zsh/zz:
	mkdir -p -- '$(dir $@)'
	touch -- '$@'
