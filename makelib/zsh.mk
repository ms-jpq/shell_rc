.PHONY: zshrc
all: zshrc

ZSH := ./layers/posix/home/.zshenv $(shell printf -- '%s ' ./zsh/**/*)

$(GIT_TMP)/dircolors.sh: $(GIT_TMP)/dircolors-solarized
	case "$$OSTYPE" in
	darwin*)
		DC='$(BREW_PREFIX)/opt/coreutils/libexec/gnubin/dircolors'
		;;
	*)
		DC='dircolors'
		;;
	esac
	TERM=xterm-256color "$$DC" --bourne-shell -- '$</dircolors.256dark' > '$@'


define ZSH_TEMPLATE

zshrc: $(TMP)/$1/rc/.config/zsh/.zshrc $(TMP)/$1/rc/.bashrc

$(TMP)/$1/rc/.config/zsh/.zshrc $(TMP)/$1/rc/.bashrc &: ./libexec/zsh.sh $(ZSH) $(GIT_TMP)/dircolors.sh $(GIT_TMP)/z $(GIT_TMP)/fzf
	'$$<' '$1' '$(GIT_TMP)' '$(TMP)/$1/rc/.config/zsh' '$(TMP)/$1/rc'

endef

$(foreach os,$(GOOS),$(eval $(call ZSH_TEMPLATE,$(os))))
