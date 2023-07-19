MAKEFLAGS += --jobs
MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --warn-undefined-variables
SHELL := bash
.ONESHELL:
.SHELLFLAGS := -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar -c

.DEFAULT_GOAL := all

CONFIG := $(HOME)/.config
LOCAL := $(HOME)/.local
BIN := $(LOCAL)/bin
OPT := $(LOCAL)/opt
SHARE := $(LOCAL)/share
CACHE = $(HOME)/.cache
TMP := $(CACHE)/initd

.PHONY: clean clobber

clean:
	shopt -u failglob
	rm -rf -- $(TMP)

clobber: clean
	shopt -u failglob
	rm -rf --

CURL := curl --fail --location --no-progress-meter

define META_2D
$(foreach line,$($(1)),$(eval $(call $(2),$(firstword $(subst #, ,$(line))),$(lastword $(subst #, ,$(line))))))
endef

$(TMP):
	mkdir -p -- '$@'

include env.mk
include makelib/*.mk

all: pkg git zsh tmux conf nvim