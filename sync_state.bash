#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

# Remark: When `sync_state.bash` is missing, `setup.bash` may still install depedencies from
# `target_state.yaml`, but only the mandatory ones. In `verify_setup.bash`, this reduces the build
# time in several Podman images by avoiding compiling Pixi if it is not needed.

bash sync.bash current_state.yaml target_state.yaml
