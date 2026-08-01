#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

source common.bash

main() {
    ensure_vscodium_is_installed
    for ext in leanprover.lean4 maximedenes.vscoq timonwong.shellcheck tombi-toml.tombi rust-lang.rust-analyzer; do
        if ! codium --list-extensions | grep -Fxq "$ext"; then
            run codium --install-extension "$ext"
        fi
    done
}

ensure_vscodium_is_installed() {
    if ! command -v codium >/dev/null 2>&1; then
        install_apt_package_if_executable_is_missing wget
        ensure_apt_packages_are_installed ca-certificates gnupg
        # See https://vscodium.com/
        echo + Install VSCodium
        wget -qO - https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg \
            | gpg --dearmor \
            | sudo dd of=/usr/share/keyrings/vscodium-archive-keyring.gpg
        echo -e 'Types: deb\nURIs: https://download.vscodium.com/debs\nSuites: vscodium\nComponents: main\nArchitectures: amd64 arm64\nSigned-by: /usr/share/keyrings/vscodium-archive-keyring.gpg' \
            | sudo tee /etc/apt/sources.list.d/vscodium.sources
        run sudo apt-get update
        run sudo apt-get install -y --no-install-recommends codium
    fi
}

main
