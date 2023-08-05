.PHONY: tmux

ifneq (aarch64-linux, $(MACHTYPE)-$(OS))
	tmux: $(SHARE)/tmux
endif

$(SHARE)/tmux:
	python3 -m venv --upgrade -- '$@'
	'$@/$(PY_BIN)/pip' install --require-virtualenv --upgrade --requirement '$(call UNESC_DRIVE,$(CONFIG)/tmux/requirements.txt)'
