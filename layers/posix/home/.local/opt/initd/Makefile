MAKEFLAGS += --jobs
MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --warn-undefined-variables
SHELL := bash
.ONESHELL:
.SHELLFLAGS := --norc --noprofile -Eeuo pipefail -O dotglob -O nullglob -O extglob -O failglob -O globstar -c

.DEFAULT_GOAL := all

include env.mk

ifeq ($(OS),nt)
HOME := $(subst :,\:,$(HOME))
endif
CONFIG := $(HOME)/.config
LOCAL := $(HOME)/.local
BIN := $(LOCAL)/bin
OPT := $(LOCAL)/opt
SHARE := $(LOCAL)/share
CACHE = $(HOME)/.cache
TMP := $(CACHE)/initd
NPROC := $(shell ./libexec/nproc.sh)

# TODO: gnumake 4.4 .WAIT
.PHONY: clean clobber .WAIT

CURL := curl --fail --location --no-progress-meter

define META_2D
$(foreach line,$($1),$(eval $(call $2,$(firstword $(subst !, ,$(line))),$(lastword $(subst !, ,$(line))))))
endef

ifeq ($(OS),nt)
define UNESC_DRIVE
$(subst \:,:,$(subst /,\,$1))
endef
else
define UNESC_DRIVE
$1
endef
endif

clean:
	shopt -u failglob
	rm -v -rf -- $(TMP)

clobber: clean
	shopt -u failglob
	rm -v -rf --

$(TMP):
	mkdir -v -p -- '$@'

include makelib/*.mk

all: git curl zsh tmux conf nvim
