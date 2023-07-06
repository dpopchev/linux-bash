MAKEFLAGS += --warn-undefined-variables

SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c

.DELETE_ON_ERROR:
.SUFFIXES:

.DEFAULT_GOAL := help

.PHONY: help ### show this menu
help:
	@sed -nr '/#{3}/{s/\.PHONY:/--/; s/\ *#{3}/:/; p;}' ${MAKEFILE_LIST}

FORCE:

inspect-%: FORCE
	@echo $($*)

define log
	printf "%-60s %20s \n" $(1) $(2)
endef

define add_gitignore
	echo $(1) >> .gitignore;
	sort --unique --output .gitignore{,};
endef

define del_gitignore
	if [ -e .gitignore ]; then \
		sed --in-place '\,$(1),d' .gitignore;\
		sort --unique --output .gitignore{,};\
	fi
endef
