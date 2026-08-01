#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

source common.bash

if ! command -v vivaldi >/dev/null 2>&1; then
    install_apt_package_if_executable_is_missing wget
    install_apt_package_if_executable_is_missing software-properties-common add-apt-repository
    ensure_apt_packages_are_installed ca-certificates gnupg
    # See https://doc.ubuntu-fr.org/vivaldi
    echo + Install Vivaldi
    wget -qO- https://repo.vivaldi.com/archive/linux_signing_key.pub | sudo apt-key add -
    run sudo add-apt-repository 'deb https://repo.vivaldi.com/archive/deb/ stable main'
    run sudo apt-get update
    run sudo apt-get install -y --no-install-recommends vivaldi-stable
fi
