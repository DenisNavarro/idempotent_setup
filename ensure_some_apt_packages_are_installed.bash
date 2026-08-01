#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

source common.bash

install_apt_package_for_each_missing_executable vlc gimp
