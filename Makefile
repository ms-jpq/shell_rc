MAKEFLAGS += --jobs
MAKEFLAGS += --no-builtin-rules
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
	rm -rf --

NOW=$(shell date '+%Y-%m-%d-%H-%M-%S')
TMP=./tmp/$(OS)_$(NOW)

./tmp:
	mkdir -p -- '$@'

$(TMP): ./tmp
	mkdir -p -- '$@'

include makelib/*.mk