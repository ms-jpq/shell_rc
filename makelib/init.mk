.PHONY: venv

define PYDEPS
from itertools import chain
from subprocess import check_call
from sys import executable

from tomli import load

toml = load(open("pyproject.toml", "rb"))

project = toml["project"]
check_call(
    (
        executable,
        "-m",
        "pip",
        "install",
        "--upgrade",
        "--",
        *project.get("dependencies", ()),
        *chain.from_iterable(project["optional-dependencies"].values()),
    )
)
endef
export -- PYDEPS

venv: $(VENV)/$(PY_BIN)
$(VENV)/$(PY_BIN):
	python3 -m venv -- '$(@D)'
	'$@/python' -m pip install --upgrade -- tomli
	'$@/python' <<< '$(PYDEPS)'

./node_modules/.bin:
	npm install --ignore-scripts --no-package-lock

V_SHELLCHECK = $(shell ./libexec/gh-latest.sh $(TMP) koalaman/shellcheck)
V_SHFMT      = $(shell ./libexec/gh-latest.sh $(TMP) mvdan/sh)
V_LUALS      = $(shell ./libexec/gh-latest.sh $(TMP) LuaLS/lua-language-server)

HADO_OS      = $(shell sed -E -e 's#darwin#macos#' <<<'$(OS)')
ifeq ($(HOSTTYPE), aarch64)
HADO_ARCH    = $(GOARCH)
LUALS_ARCH   = arm64
else
HADO_ARCH    = $(HOSTTYPE)
LUALS_ARCH   = x64
endif


$(VAR)/bin/shellcheck: | $(VAR)/bin
	URI='https://github.com/koalaman/shellcheck/releases/latest/download/shellcheck-$(V_SHELLCHECK).$(OS).x86_64.tar.xz'
	$(CURL) -- "$$URI" | tar --extract --xz --file - --directory '$(VAR)/bin' --strip-components 1 -- 'shellcheck-$(V_SHELLCHECK)/shellcheck'
	chmod +x '$@'

$(VAR)/bin/hadolint: | $(VAR)/bin
	URI='https://github.com/hadolint/hadolint/releases/latest/download/hadolint-$(HADO_OS)-$(HADO_ARCH)'
	$(CURL) --output '$@' -- "$$URI"
	chmod +x '$@'

$(VAR)/bin/shfmt: | $(VAR)/bin
	URI='https://github.com/mvdan/sh/releases/latest/download/shfmt_$(V_SHFMT)_$(OS)_$(GOARCH)'
	$(CURL) --output '$@' -- "$$URI"
	chmod +x '$@'

$(VAR)/bin/stylua: | $(VAR)/bin
	URI='https://github.com/JohnnyMorganz/StyLua/releases/latest/download/stylua-$(HADO_OS)-$(HOSTTYPE).zip'
	$(CURL) -- "$$URI" | bsdtar --extract --file - --directory $(VAR)/bin
	chmod +x '$@'

$(VAR)/opt/lua-language-server/bin/lua-language-server: | $(VAR)
	URI='https://github.com/LuaLS/lua-language-server/releases/latest/download/lua-language-server-$(V_LUALS)-$(OS)-$(LUALS_ARCH).tar.gz'
	mkdir -v -p -- '$(VAR)/opt/lua-language-server'
	$(CURL) -- "$$URI" | tar --extract --gzip --file - --directory '$(VAR)/opt/lua-language-server'


.PHONY: hammerspoon

$(VAR)/hammerspoon/EmmyLua.spoon/init.lua: | $(VAR)
	URI='https://github.com/Hammerspoon/Spoons/raw/master/Spoons/EmmyLua.spoon.zip'
	mkdir -v -p -- '$(VAR)/hammerspoon'
	$(CURL) -- "$$URI" | bsdtar --extract --file - --directory '$(VAR)/hammerspoon'

hammerspoon: $(VAR)/hammerspoon/EmmyLua.spoon/init.lua
	LUA='package.path = package.path .. ";$(CURDIR)/var/hammerspoon/?.spoon/init.lua"; hs.loadSpoon("EmmyLua")'
	hs -a -q -c "$$LUA"
