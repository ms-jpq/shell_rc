.PHONY: pipx clobber.pipx

PIPX := $(OPT)/pipx/venvs

clobber: clobber.pipx
clobber.pipx:
	rm -v -rf -- '$(OPT)/pipx' '$(PIPX)'

$(OPT)/pipx:
	python3 -m venv --upgrade -- '$@'

$(OPT)/pipx/bin/pipx: | $(OPT)/pipx
	'$(OPT)/pipx/bin/pip' install --require-virtualenv --upgrade -- pipx

define PIPX_TEMPLATE

pipx: .WAIT $(PIPX)/$1
$(PIPX)/$1: $(OPT)/pipx/bin/pipx
	if [[ -d '$$@' ]]; then
		'$$<' upgrade -- '$2'
	else
		'$$<' install -- '$2'
	fi

endef

define PIP_PKGS

gay                   gay
graphtage             graphtage
httpie                httpie
lookatme              lookatme
markdown-live-preview markdown_live_preview
py-dev                https://github.com/ms-jpq/py-dev/archive/dev.tar.gz
sortd                 sortd

endef

PIP_PKGS := $(shell tr -s ' ' '#' <<<'$(PIP_PKGS)')

$(call META_2D,PIP_PKGS,PIPX_TEMPLATE)
