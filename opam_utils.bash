#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")"/common.bash

ensure_opam_packages_are_available() {
    _ensure_opam_is_available_and_initialized
    if [[ ":$PATH:" != *":$HOME/.opam/default/bin:"* ]]; then
        export PATH="$PATH:$HOME/.opam/default/bin"
    fi
}

pin_in_env_if_opam_package_is_not_pinned_to() {
    local env="$1" package="$2" version="$3"
    _ensure_opam_is_available_and_initialized
    if ! _opam_package_is_pinned_to "$package" "$version"; then
        if [[ "$env" == *pkgconfig* ]]; then
            local infix=(env PKG_CONFIG_PATH="$PWD/.pixi/envs/$env/lib/pkgconfig")
        else
            local infix=()
        fi
        run "${infix[@]}" pixi run -e "$env" \
          opam exec -- opam pin --no-depexts --yes add "$package" "$version"
    fi
}

ensure_opam_package_is_pinned_to() {
    local package="$1" version="$2"
    _ensure_opam_is_available_and_initialized
    if ! _opam_package_is_pinned_to "$package" "$version"; then
        run opam exec -- opam pin --no-depexts --yes add "$package" "$version"
    fi
}

_ensure_opam_is_available_and_initialized() {
    _ensure_opam_is_available
    if [ ! -d ~/.opam ]; then
        run pixi run -e curl-make opam init --no-setup --disable-sandboxing
    fi
}

_ensure_opam_is_available() {
    ensure_recipes_are_available
    ensure_mandatory_exe_is_installed_with opam pixi
}

_opam_package_is_pinned_to() {
    local package="$1" version="$2"
    local line
    while IFS= read -r line; do
        [[ "$line" == "$package.$version "* ]] && [[ "$line" != *' (uninstalled) '* ]] && return 0
    done < <(opam pin list 2>/dev/null)
    # Rk: 2>/dev/null avoids '[WARNING] Running as root is not recommended' inside a container
    return 1
}
