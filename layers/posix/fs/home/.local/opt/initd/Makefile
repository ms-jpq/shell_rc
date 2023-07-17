MAKEFLAGS += --jobs
MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --warn-undefined-variables
SHELL := bash
.ONESHELL:
.SHELLFLAGS := -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -c

.DEFAULT_GOAL := all

CONFIG := $(HOME)/.config
LOCAL := $(HOME)/.local
BIN := $(LOCAL)/bin
OPT := $(LOCAL)/opt
CACHE = $(HOME)/.cache
TMP := $(CACHE)/initd

define MACH_DETECT
case "$$MACHTYPE" in
aarch64*)
  printf -- '%s' aarch64
  ;;
x86_64*)
  printf -- '%s' x86_64
  ;;
*)
  exit 1
  ;;
esac
endef

MACHTYPE := $(shell $(MACH_DETECT))
ifeq ($(MACHTYPE), aarch64)
	GOARCH := arm64
else
	GOARCH := amd64
endif

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

include makelib/*.mk

all: pkg git zsh conf
