.PHONY: tmux

ifneq (aarch64-linux, $(MACHTYPE)-$(OS))
tmux: $(SHARE)/tmux
endif

$(SHARE)/tmux: $(CONFIG)/tmux/requirements.txt | pkg.posix
	/usr/bin/python3 -m venv -- '$@'
	'$@/bin/pip' install --require-virtualenv --upgrade --requirement '$<'

