.PHONY: conf conf.posix conf.posix.ssh conf.posix.git

conf: conf.posix
conf.posix: $(CONFIG)/git/config conf.posix.ssh

ifeq (nt, $(OS))
GIT_BIN :=
else
GIT_BIN := /usr/bin/git
endif

$(CONFIG)/git/config: | $(GIT_BIN)
	touch -- '$$@'
	HOME='$(call UNESC_DRIVE,$(HOME))' git config --global include.path user_config

conf.posix.ssh:
	./libexec/line-in-file.sh '$(call UNESC_DRIVE,$(HOME))/.ssh/config' 'Include ~/.config/ssh/*.conf'
