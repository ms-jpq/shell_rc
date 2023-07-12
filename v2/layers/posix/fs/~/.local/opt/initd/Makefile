MAKEFLAGS += --jobs
MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --warn-undefined-variables
SHELL := bash
.DELETE_ON_ERROR:
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

LOCAL := $(HOME)/.local
CONFIG := $(HOME)/.config
OPT := $(LOCAL)/opt

include makelib/*.mk

all: touch git
