#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

source opam_utils.bash

ensure_opam_packages_are_available
first_install=false
command -v frama-c >/dev/null 2>&1 || first_install=true
ensure_apt_packages_are_installed libcairo2-dev libexpat1-dev libgmp-dev libgtk-3-dev libgtksourceview-3.0-dev zlib1g-dev pkg-config
pin_in_env_if_opam_package_is_not_pinned_to autoconf-graphviz-make frama-c 32.0
if [ "$first_install" == true ]; then
    run opam exec -- why3 config detect
fi

# 2026-06-24: edit pixi.toml in the script:
# pixi add --feature autoconf autoconf
# pixi add --feature graphviz graphviz
# pixi workspace environment add autoconf-graphviz-make -f autoconf -f graphviz -f make --solve-group default
