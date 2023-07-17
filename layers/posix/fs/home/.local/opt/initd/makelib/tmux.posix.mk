.PHONY: tmux

# tmux: $(SHARE)/tmux

$(SHARE)/tmux: $(CONFIG)/tmux/requirements.txt | pkg.posix
	/usr/bin/python3 -m venv -- '$@'
	'$@/bin/pip' install --require-virtualenv --upgrade --requirement '$<'

