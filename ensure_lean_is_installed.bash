#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

source common.bash

# https://github.com/leanprover/lean4/releases
LEAN_VERSION=4.35.0

main() {
    ensure_elan_is_available
}

ensure_elan_is_available() {
    if ! command -v elan  >/dev/null 2>&1; then
        ensure_elan_is_installed
        if [[ ":$PATH:" != *":$HOME/.elan/bin:"* ]]; then
            export PATH="$PATH:$HOME/.elan/bin"
        fi
    fi
    ensure_elan_has_toolchain_version "$LEAN_VERSION"
    # TODO: elan default "$LEAN_VERSION"
}

ensure_elan_is_installed() {
    if [ ! -f ~/.elan/bin/elan ]; then
        # See https://github.com/leanprover/elan
        curl_https_tls_1_3 -O https://elan.lean-lang.org/elan-init.sh
        run chmod +x elan-init.sh
        run ./elan-init.sh -y --no-modify-path --default-toolchain "$LEAN_VERSION"
        run rm elan-init.sh
    fi
}

ensure_elan_has_toolchain_version() {
    local version="$1"
    if ! elan_has_toolchain_version "$version"; then
        run elan toolchain install "$version"
    fi
}

elan_has_toolchain_version() {
    local version="$1"
    local line
    while IFS= read -r line; do
        [ "$line" == leanprover/lean4:v"$version" ] && return 0
    done < <(elan toolchain list)
    return 1
}

main
