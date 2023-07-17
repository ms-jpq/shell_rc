MAKEFLAGS += --jobs
MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --warn-undefined-variables
SHELL := bash
.ONESHELL:
.SHELLFLAGS := -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -c

.DEFAULT_GOAL := all

.PHONY: clean clobber

clean:
	shopt -u failglob
	rm -rf --

clobber: clean
	shopt -u failglob
	rm -rf --

CONFIG := $(HOME)/.config
LOCAL := $(HOME)/.local
BIN := $(LOCAL)/bin
OPT := $(LOCAL)/opt

MACHTYPE := $(shell printf -- '%s' "$$MACHTYPE")
ifeq ($(MACHTYPE), aarch64)
	DPKG_ARCH := arm64
else
	DPKG_ARCH := amd64
endif

define META_2D
$(foreach line,$($(1)),$(eval $(call $(2),$(firstword $(subst #, ,$(line))),$(lastword $(subst #, ,$(line))))))
endef

include makelib/*.mk

all: pkg git zsh conf
