.PHONY: zsh zsh.posix

zsh: zsh.posix

zsh.posix: $(STATE)/zsh/zz

$(STATE)/zsh:
	mkdir -v -p -- '$@'

$(STATE)/zsh/zz: | $(STATE)/zsh
	touch -- '$@'
