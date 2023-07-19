.PHONY: tmux

ifneq (aarch64-linux, $(MACHTYPE)-$(OS))
tmux: $(SHARE)/tmux
endif

$(SHARE)/tmux:
	/usr/bin/python3 -m venv --upgrade -- '$@'
	'$@/bin/pip' install --require-virtualenv --upgrade --requirement '$<'
	touch -- '$@'
