
.DELETE_ON_ERROR:
MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --warn-undefined-variables

.PHONY: setup # Launch `setup.bash`
setup:
	bash setup.bash

#############################################
# Other phony targets in alphabetical order #
#############################################

.PHONY: clean # Remove what is in `.gitignore`
clean:
	git clean -dXf

.PHONY: git_hooks # Update the Git hooks
git_hooks: .git/hooks/commit-msg .git/hooks/pre-commit

.PHONY: help # Print each phony target with its description
help:
	@grep '^.PHONY: .* # ' Makefile | sed 's/\.PHONY: \(.*\) # \(.*\)/\1\t\2/' | expand -t 10

################
# File targets #
################

.git/hooks/commit-msg: commit-msg.sh
	cp -- $< $@

.git/hooks/pre-commit: verify_setup.bash
	cp -- $< $@
