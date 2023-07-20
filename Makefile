MAKEFLAGS += --check-symlink-times
MAKEFLAGS += --jobs
MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --no-builtin-variables
MAKEFLAGS += --shuffle
MAKEFLAGS += --warn-undefined-variables
SHELL := bash
.DELETE_ON_ERROR:
.ONESHELL:
.SHELLFLAGS := -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar -c

.DEFAULT_GOAL := help

.PHONY: clean clobber

clean:
	shopt -u failglob
	rm -rf -- ./tmp

clobber: clean
	shopt -u failglob
	rm -rf -- ./var ./.venv ./node_modules

GOOS := darwin ubuntu nt
CURL := curl --fail --location --no-progress-meter

TMP := ./tmp

$(TMP):
	mkdir -p -- '$@'

./var/bin:
	mkdir -p -- '$@'

include makelib/*.mk
