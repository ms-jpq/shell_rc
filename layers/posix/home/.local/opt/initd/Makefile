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

DIE := $(shell [[ -f /.die ]] && printf -- '%s' 1)
ifeq ($(DIE),1)
$(error "DIE")
endif

include lib/*.mk

ifeq ($(OS),nt)
HOME := $(USERPROFILE)
HP := $(call NT_2_UNIX,$(HOME))
export -- HOME
else
HP := $(HOME)
endif

CONFIG := $(HP)/.config
LOCAL := $(HP)/.local
BIN := $(LOCAL)/bin
OPT := $(LOCAL)/opt
SHARE := $(LOCAL)/share
CACHE := $(HP)/.cache
STATE := $(LOCAL)/state
TP := $(CACHE)/initd

# TODO: gnumake 4.4 .WAIT
.PHONY: noop clean clobber .WAIT

CURL := curl --fail --location --remove-on-error --create-dirs --no-progress-meter

clean:
	shopt -u failglob
	rm -v -rf --

clobber: clean
	shopt -u failglob
	rm -v -rf --

$(TP):
	mkdir -v -p -- '$@'

include makelib/*.mk

noop:
all: git curl zsh conf pkg mail

ifneq ($(OS),nt)
all: pipx
endif

