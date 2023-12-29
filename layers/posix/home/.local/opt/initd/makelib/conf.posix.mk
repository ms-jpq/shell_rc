.PHONY: conf conf.posix

conf: conf.posix
conf.posix: $(CONFIG)/git/config

ifeq (nt, $(OS))
GIT_BIN :=
else
GIT_BIN := /usr/bin/git
endif

$(CONFIG)/git/config: | $(GIT_BIN)
	git config --file '$@' -- include.path user_config
