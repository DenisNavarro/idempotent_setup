.DELETE_ON_ERROR:
MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --warn-undefined-variables

.PHONY: all
all : \
  idempotent_setup \
  rust_pocs \
  sync_install

.PHONY: pull
pull :
	find . -mindepth 1 -maxdepth 1 -type d -exec env -C {} git pull \;

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
