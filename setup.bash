#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

main() {
    # All scripts called by `setup.bash` are optional but there are file dependencies.
    local fn
    fn=check_if_first_file_exists_then_next_files_exist
    $fn ensure_hardlinks_are_up_to_date.bash common.bash
    $fn ensure_vivaldi_is_installed.bash common.bash
    $fn ensure_vscodium_and_its_extensions_are_installed.bash common.bash
    $fn ensure_some_apt_packages_are_installed.bash common.bash
    $fn target_fish_fresh.yaml common.bash sync.bash target_state.yaml
    $fn sync_state.bash common.bash sync.bash target_state.yaml
    $fn target_pixi_uv.yaml common.bash sync.bash target_state.yaml
    $fn target_cargo_install_1.yaml common.bash sync.bash target_state.yaml pixi.toml pixi.lock
    $fn target_cargo_install_2.yaml common.bash sync.bash target_state.yaml
    $fn target_cargo_install_3.yaml common.bash sync.bash target_state.yaml pixi.toml pixi.lock
    $fn target_extra.yaml sync.bash target_state.yaml pixi.toml pixi.lock
    $fn ensure_lean_is_installed.bash common.bash
    $fn ensure_rocq_is_installed.bash common.bash opam_utils.bash target_state.yaml pixi.toml pixi.lock
    $fn ensure_framac_is_installed.bash common.bash opam_utils.bash target_state.yaml pixi.toml pixi.lock

    # In the below script, the hardlinks are mainly dotfiles.
    execute_if_bash_file_exists ensure_hardlinks_are_up_to_date.bash

    # The below script is not called by `verify_setup.bash` because, inside a container,
    # `apt-get install -y --no-install-recommends vivaldi-stable` fails:
    # `E: Unable to locate package vivaldi-stable`
    execute_if_bash_file_exists ensure_vivaldi_is_installed.bash

    # The below script is not called by `verify_setup.bash` because VSCodium does not like to be
    # executed from a super user.
    execute_if_bash_file_exists ensure_vscodium_and_its_extensions_are_installed.bash

    execute_if_bash_file_exists ensure_some_apt_packages_are_installed.bash

    # Execute the commands from the target files if they are not already in the "current" files.
    # If a "current" file exists already, uninstall its packages not present in its target file.
    # The target files could have been merged into a single YAML. But, by doing so, editing even a
    # single line of it would force `verify_setup.bash` to execute all commands in a Podman image.
    sync_if_target_exists current_fish_fresh.yaml target_fish_fresh.yaml
    execute_if_bash_file_exists sync_state.bash
    sync_if_target_exists current_pixi_uv.yaml target_pixi_uv.yaml
    sync_if_target_exists current_cargo_install_1.yaml target_cargo_install_1.yaml
    sync_if_target_exists current_cargo_install_2.yaml target_cargo_install_2.yaml
    sync_if_target_exists current_cargo_install_3.yaml target_cargo_install_3.yaml
    sync_if_target_exists current_extra.yaml target_extra.yaml

    # The below scripts install formal proof technologies.
    execute_if_bash_file_exists ensure_lean_is_installed.bash
    execute_if_bash_file_exists ensure_rocq_is_installed.bash
    execute_if_bash_file_exists ensure_framac_is_installed.bash
}

check_if_first_file_exists_then_next_files_exist() {
    local first_file="$1"
    if [ -f "$first_file" ]; then
        local file
        for file in "${@:2}"; do
            if [ ! -f "$file" ]; then
                >&2 echo "$first_file requires $file which is missing"
                exit 1
            fi
        done
    fi
}

execute_if_bash_file_exists() {
    local file="$1"
    if [ -f "$file" ]; then
        bash "$file"
    fi
}

sync_if_target_exists() {
    local current_file="$1"
    local target_file="$2"
    if [ -f "$target_file" ]; then
        bash sync.bash "$current_file" "$target_file"
    fi
}

main
