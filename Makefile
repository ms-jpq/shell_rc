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

.PHONY: all clean clobber

clean:
	shopt -u failglob
	rm -v -rf -- '$(TMP)'

clobber: clean
	shopt -u failglob
	rm -v -rf -- '$(VAR)' '$(VENV)' ./node_modules

GOOS := darwin ubuntu nt
CURL := curl --fail --location --remove-on-error --create-dirs --no-progress-meter
VAR  := var
TMP  := $(VAR)/tmp
VENV := ./.venv

$(VAR) $(VAR)/bin $(TMP):
	mkdir -v -p -- '$@'

include layers/posix/home/.local/opt/initd/lib/*.mk
include makelib/*.mk
