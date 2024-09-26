.PHONY: pipx clobber.pipx

ifeq ($(OS),darwin)
PIPX := $(LOCAL)/pipx/venvs
else
PIPX := $(LOCAL)/share/pipx/venvs
endif

PIPX_E := $(call UNIX_2_NT,$(OPT)/pipx/$(PY_BIN)/pipx)
ifeq ($(OS),nt)
PIPX_E := $(PIPX_E).exe
endif

PIPX_EX := env -- 'HOME=$(HOME)' 'USERPROFILE=$(HOME)' ./libexec/flock.sh '$(PIPX_E)' '$(PIPX_E)'


clobber: clobber.pipx
clobber.pipx:
	rm -v -rf -- '$(OPT)/pipx' '$(PIPX)'

$(OPT)/pipx:
	'$(PY_EXE)' -m venv --upgrade -- '$@'

$(OPT)/pipx/$(PY_BIN)/pipx: | $(OPT)/pipx
	'$(call UNIX_2_NT,$(OPT)/pipx/$(PY_BIN)/$(PY_EXE))' -m pip install --require-virtualenv --upgrade -- pipx

pipx: $(BIN)/pipx
$(BIN)/pipx: $(OPT)/pipx/$(PY_BIN)/pipx
	ln -v -snf -- '$<' '$@'

define PIPX_TEMPLATE

pipx: .WAIT $(PIPX)/$1
$(PIPX)/$1: | $(OPT)/pipx/$(PY_BIN)/pipx
	export -- PIPX_HOME='$(dir $(PIPX))'
	if [[ -d '$$@' ]]; then
		$(PIPX_EX) upgrade -- '$2'
	else
		$(PIPX_EX) install -- '$2'
	fi

endef

# lookatme              lookatme
define PIP_PKGS

gay                   gay
markdown-live-preview markdown_live_preview
posting               posting
sortd                 sortd

endef

PIP_PKGS := $(shell tr -s -- ' ' '!' <<<'$(PIP_PKGS)')

$(call META_2D,PIP_PKGS,PIPX_TEMPLATE)
