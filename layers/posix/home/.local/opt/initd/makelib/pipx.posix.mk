.PHONY: pipx clobber.pipx

ifeq (nt, $(OS))
PY_BIN := Scripts
else
PY_BIN := bin
endif

PIPX := $(LOCAL)/pipx/venvs

clobber: clobber.pipx
clobber.pipx:
	rm -v -rf -- '$(OPT)/pipx' '$(PIPX)'

$(OPT)/pipx:
	python3 -m venv --upgrade -- '$@'

$(OPT)/pipx/$(PY_BIN)/pipx: | $(OPT)/pipx
	'$(OPT)/pipx/$(PY_BIN)/pip' install --require-virtualenv --upgrade -- pipx


PIPX_EX := ./libexec/linux-lock.sh $(OPT)/pipx/$(PY_BIN)/pipx

define PIPX_TEMPLATE

pipx: $(PIPX)/$1
$(PIPX)/$1: | .WAIT $(OPT)/pipx/$(PY_BIN)/pipx
	if [[ -d '$$@' ]]; then
		$(PIPX_EX) upgrade -- '$2'
	else
		$(PIPX_EX) install -- '$2'
	fi

endef

# lookatme              lookatme
define PIP_PKGS

gay                   gay
graphtage             graphtage
httpie                httpie
markdown-live-preview markdown_live_preview
sortd                 sortd

endef

PIP_PKGS := $(shell tr -s ' ' '!' <<<'$(PIP_PKGS)')

$(call META_2D,PIP_PKGS,PIPX_TEMPLATE)
