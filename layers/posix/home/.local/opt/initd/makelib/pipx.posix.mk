.PHONY: pipx clobber.pipx

PIPX := $(LOCAL)/pipx/venvs

clobber: clobber.pipx
clobber.pipx:
	rm -v -rf -- '$(OPT)/pipx' '$(PIPX)'

$(OPT)/pipx: | /usr/share/doc/python3-venv
	python3 -m venv --upgrade -- '$@'

$(OPT)/pipx/bin/pipx: | $(OPT)/pipx
	'$(OPT)/pipx/bin/pip' install --require-virtualenv --upgrade -- pipx

define PIPX_TEMPLATE

.NOTPARALLEL: $(PIPX)/$1
pipx: $(PIPX)/$1
$(PIPX)/$1: | $(OPT)/pipx/bin/pipx
	if [[ -d '$$@' ]]; then
		'$(OPT)/pipx/bin/pipx' upgrade -- '$2'
	else
		'$(OPT)/pipx/bin/pipx' install -- '$2'
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
