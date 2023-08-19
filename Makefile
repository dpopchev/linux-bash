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

backup_suffix := dpopchevbak
define backup_config
	if [ -e "$(1)" ]; then \
		mv --force --no-target-directory --backup=numbered \
		"$(1)" "$(1).$(backup_suffix)";\
	fi
endef

stamp_dir := .stamps
src_dir := src

configs := bash_profile bashrc.private
config_dsts := $(addprefix ${HOME}/.,$(configs))
config_stamps := $(addprefix $(stamp_dir)/,$(addsuffix .stamp,$(configs)))

configs += bashrc.d
config_dsts += ${HOME}/.config/bashrc.d
config_stamps += $(stamp_dir)/bashrc.d.stamp

$(stamp_dir):
	@$(call add_gitignore,$@)
	@mkdir --parents $@
	@$(call log,'create $@','[done]')

profile_config := $(src_dir)/profile
profile_dst := ${HOME}/.profile
profile_stamp := $(stamp_dir)/profile.stamp
$(profile_stamp):
	@$(call backup_config,$(profile_dst))
	@ln -s $(realpath $(profile_config)) $(profile_dst)
	@touch $@
	@$(call log,'install profile','[done]')

$(config_stamps): $(stamp_dir)/%.stamp: | $(stamp_dir)
	@$(call backup_config,$(filter %$*,$(config_dsts)))
	@ln -s $(realpath $(src_dir)/$(filter %$*,$(configs))) $(filter %$*,$(config_dsts))
	@touch $@
	@$(call log,'install $*','[done]')

install_config_targets := $(addprefix install-,$(configs))
.PHONY: $(install_config_targets)
$(install_config_targets): install-%: $(stamp_dir)/%.stamp

.PHONY: install
install: $(install_config_targets) $(profile_stamp)

uninstall_config_targets := $(addprefix uninstall-,$(configs))
.PHONY: $(uninstall_config_targets)
$(uninstall_config_targets): uninstall-%:
	@rm --force $(filter %$*,$(config_dsts))
	@if [ -e $(filter %$*,$(config_dsts)).$(backup_suffix) ]; then \
		mv --force $(filter %$*,$(config_dsts)).$(backup_suffix) $(filter %$*,$(config_dsts));\
	fi
	@if [ -e $(filter %$*,$(config_dsts)) ]; then \
		$(call log,'restore config $*','[done]');\
	fi
	@if [ ! -e $(filter %$*,$(config_dsts)) ]; then \
		$(call log,'restore config $*; inspect localtion manually','[fail]');\
	fi
	@rm --force $(stamp_dir)/$*.stamp

uninstall-profile:
	@rm --force $(profile_dst)
	@if [ -e $(profile_dst).$(backup_suffix) ]; then \
		mv --force $(profile_dst).$(backup_suffix) $(profile_dst);\
	fi
	@if [ -e $(profile_dst) ]; then \
		$(call log,'restore config profile','[done]');\
	fi
	@if [ ! -e $(profile_dst) ]; then \
		$(call log,'restore config profile; inspect localtion manually','[fail]');\
	fi
	@rm --force $(profile_stamp)

.PHONY: uninstall
uninstall: $(uninstall_config_targets) uninstall-profile

.PHONY: clean
clean:
	@rm --recursive --force $(stamp_dir)
