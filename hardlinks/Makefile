.DELETE_ON_ERROR:
MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --warn-undefined-variables

.PHONY: all # Download Git repositories
all : \
  idempotent_setup \
  rust_pocs \
  sync_install

#############################################
# Other phony targets in alphabetical order #
#############################################

.PHONY: help # Print each phony target with its description
help:
	@grep '^.PHONY: .* # ' Makefile | sed 's/\.PHONY: \(.*\) # \(.*\)/\1\t\2/' | expand -t 5

.PHONY: pull # Do `git pull` on each downloaded Git repository
pull :
	find . -mindepth 1 -maxdepth 1 -type d -exec echo + env -C {} git pull \; \
	                                       -exec        env -C {} git pull \;

#####################
# Directory targets #
#####################

# https://github.com/DenisNavarro/idempotent_setup
idempotent_setup :
	git clone git@github.com:DenisNavarro/idempotent_setup.git
	env -C $@ make git_hooks

# https://github.com/DenisNavarro/rust_pocs
rust_pocs :
	git clone git@github.com:DenisNavarro/rust_pocs.git
	env -C $@ make git_hooks

# https://github.com/DenisNavarro/sync_install
sync_install :
	git clone git@github.com:DenisNavarro/sync_install.git
	env -C $@ make git_hooks
