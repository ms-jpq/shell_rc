define PYDEPS
from itertools import chain
from os import execl
from sys import executable

from tomli import load

toml = load(open("pyproject.toml", "rb"))

project = toml["project"]
execl(
  executable,
  executable,
  "-m",
  "pip",
  "install",
  "--upgrade",
  "--",
  *project.get("dependencies", ()),
  *chain.from_iterable(project["optional-dependencies"].values()),
)
endef
export -- PYDEPS

./.venv/bin:
	python3 -m venv -- './.venv'
	'$@/python3' -m pip install --upgrade -- tomli
	'$@/python3' <<< '$(PYDEPS)'

./node_modules/.bin:
	npm install --upgrade --no-package-lock


ifeq ($(HOSTTYPE), aarch64)
S5_TYPE := $(GOARCH)
else
S5_TYPE := 64bit
endif

ifeq ($(OS), nt)
S5_EXT := zip
else
S5_EXT := tar.gz
endif

V_S5CMD      = $(patsubst v%,%,$(shell ./libexec/gh-latest.sh $(VAR) peak/s5cmd))
V_SHELLCHECK = $(shell ./libexec/gh-latest.sh $(TMP) koalaman/shellcheck)
V_SHFMT      = $(shell ./libexec/gh-latest.sh $(TMP) mvdan/sh)

S5_OS        = $(shell perl -CASD -wpe 's/([a-z])/\u$$1/;s/Darwin/macOS/;s/Msys/Windows/' <<<'$(OS)')
HADO_OS      = $(shell perl -CASD -wpe 's/([a-z])/\u$$1/' <<<'$(OS)')

$(VAR)/bin/shellcheck: | $(VAR)/bin
	URI='https://github.com/koalaman/shellcheck/releases/latest/download/shellcheck-$(V_SHELLCHECK).$(OS).x86_64.tar.xz'
	$(CURL) -- "$$URI" | tar --extract --xz --file - --directory '$(VAR)/bin' --strip-components 1 "shellcheck-$(V_SHELLCHECK)/shellcheck"
	chmod +x '$@'

$(VAR)/bin/hadolint: | $(VAR)/bin
	URI='https://github.com/hadolint/hadolint/releases/latest/download/hadolint-$(HADO_OS)-x86_64'
	$(CURL) --output '$@' -- "$$URI"
	chmod +x '$@'

$(VAR)/bin/shfmt: | $(VAR)/bin
	URI='https://github.com/mvdan/sh/releases/latest/download/shfmt_$(V_SHFMT)_$(OS)_$(GOARCH)'
	$(CURL) --output '$@' -- "$$URI"
	chmod +x '$@'

$(VAR)/bin/s5cmd$(OS_EXT): | $(VAR)/bin
	URI='https://github.com/peak/s5cmd/releases/latest/download/s5cmd_$(V_S5CMD)_$(S5_OS)-$(S5_TYPE).$(S5_EXT)'
	case '$(OSTYPE)' in
	msys)
		$(CURL) --output '$(TMP)/s5cmd.zip' -- "$$URI"
		unzip -o -d '$(VAR)/bin' '$(TMP)/s5cmd.zip'
		;;
	*)
		$(CURL) -- "$$URI" | tar --extract --gz --file - --directory '$(VAR)/bin'
		;;
	esac
	chmod +x '$@'
