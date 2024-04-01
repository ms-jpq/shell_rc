MAKEFLAGS += --check-symlink-times
MAKEFLAGS += --jobs
MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --no-builtin-variables
MAKEFLAGS += --shuffle
MAKEFLAGS += --warn-undefined-variables
SHELL := bash
.DELETE_ON_ERROR:
.ONESHELL:
.SHELLFLAGS := --norc --noprofile -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar -c

.DEFAULT_GOAL := all

.PHONY: clean clobber localhost

clean:
	shopt -u failglob
	rm -v -rf -- '$(TMP)'

clobber: clean
	shopt -u failglob
	rm -v -rf -- $(VAR) ./.venv ./node_modules

GOOS := darwin ubuntu nt
CURL := curl --fail-with-body --location --no-progress-meter
VAR := var
TMP := $(VAR)/tmp

$(VAR)/bin $(TMP):
	mkdir -v -p -- '$@'

include layers/posix/home/.local/opt/initd/lib/*.mk
include $(shell shopt -u failglob && printf -- '%s ' ./makelib/*.mk)
