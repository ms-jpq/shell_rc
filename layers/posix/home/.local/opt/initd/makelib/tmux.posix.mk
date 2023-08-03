.PHONY: tmux

ifneq (aarch64-linux, $(MACHTYPE)-$(OS))
tmux: $(SHARE)/tmux
endif

$(SHARE)/tmux:
	python3 -m venv --upgrade -- '$@'
	'$@/bin/pip' install --require-virtualenv --upgrade --requirement '$(CONFIG)/tmux/requirements.txt'
	touch -- '$@'
