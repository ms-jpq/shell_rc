.PHONY: pipx clobber.pipx .WAIT
.WAIT:

PIPX := $(LOCAL)/pipx/venvs

clobber: clobber.pipx
clobber.pipx:
	rm -v -rf -- '$(OPT)/pipx' '$(PIPX)'

$(OPT)/pipx:
	python3 -m venv --upgrade -- '$@'

$(OPT)/pipx/bin/pipx: | $(OPT)/pipx
	'$(OPT)/pipx/bin/pip' install --require-virtualenv --upgrade -- pipx


PIPX_EX := ./libexec/pipx-lock.sh $(OPT)/pipx/bin/pipx

define PIPX_TEMPLATE

$(PIPX)/$1: | .WAIT
pipx: $(PIPX)/$1
$(PIPX)/$1: | $(OPT)/pipx/bin/pipx
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

PIP_PKGS := $(shell tr -s ' ' '#' <<<'$(PIP_PKGS)')

$(call META_2D,PIP_PKGS,PIPX_TEMPLATE)
