.PHONY: tmux

ifneq (aarch64-linux, $(HOSTTYPE)-$(OS))
tmux: $(SHARE)/tmux
endif

$(SHARE)/tmux:
	'$(PY_EXE)' -m venv --upgrade -- '$@'
	'$@/$(PY_BIN)/$(PY_EXE)' -m pip install --require-virtualenv --upgrade --requirement '$(call UNIX_2_NT,$(CONFIG)/tmux/requirements.txt)'
