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

.DEFAULT_GOAL := help

.PHONY: clean clobber localhost

clean:
	shopt -u failglob
	rm -v -rf -- '$(TMP)'

clobber: clean
	shopt -u failglob
	rm -v -rf -- ./var ./.venv ./node_modules

GOOS := darwin ubuntu nt
CURL := curl --fail --location --no-progress-meter
TMP := ./var/tmp
ARGV ?=

./var/bin $(TMP):
	mkdir -v -p -- '$@'

include env.mk
include makelib/*.mk

localhost:
	MAKE='$(MAKE)' RSYNC='$(RSYNC)' ./libexec/run.sh '$@' $(ARGV)
