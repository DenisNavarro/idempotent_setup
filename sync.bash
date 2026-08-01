#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

source common.bash

# `sync current.yaml target.yaml` uninstalls, installs and updates dependencies to go from the
# current state to the target state. `current.yaml` is updated after each operation.
sync() {
    local current_file="$1" target_file="$2"
    # `jaq` is almost a superset of `jq` and works with various formats, including YAML.
    ensure_jaq_is_available
    ensure_current_yaml_is_initialized "$current_file"
    sync_impl "$current_file" "$target_file" uv 'uv tool uninstall' --force
    sync_impl "$current_file" "$target_file" pixi 'pixi global uninstall' --force-reinstall
    sync_impl "$current_file" "$target_file" cargo 'cargo uninstall' --force
}

sync_impl() {
    local current_file="$1" target_file="$2" installer="$3" uninstall_cmd="$4" force_flag="$5"

    # Load the relevant parts from "$current_file" and "$target_file".
    local current_json target_json
    current_json="$(jaq -r --arg installer "$installer" '.[$installer] // {}' "$current_file")"
    target_json="$(jaq -r --arg installer "$installer" '.[$installer] // {}' "$target_file")"

    # For each package in "$current_json" but not in "$target_json", uninstall it and remove it
    # from "$current_file".
    jaq -rn --argjson current "$current_json" --argjson target "$target_json" \
      '($current | keys) - ($target | keys) | .[]' | \
      while IFS= read -r pkg; do
        run_eval "$uninstall_cmd $pkg"
        run jaq --arg installer "$installer" --arg pkg "$pkg" \
          'del(.[$installer][$pkg])' --to yaml -ji "$current_file"
    done

    # For each package in "$target_json":
    # - If the package is missing in "$current_json", install it and update "$current_file".
    # - If the package has a different installing command in "$current_json", force a reinstall
    #   and update "$current_file".
    jaq -rn --argjson json "$target_json" '$json | to_entries[] | [.key, .value] | @tsv' | \
      while IFS=$'\t' read -r pkg target_cmd; do
        current_cmd="$(jaq -rn --argjson json "$current_json" --arg pkg "$pkg" '$json[$pkg] // empty')"
        if [ "$current_cmd" != "$target_cmd" ]; then
            if [ "$installer" == uv ]; then
                ensure_uv_is_available
            elif [ "$installer" == pixi ] || [[ "$target_cmd" == *'pixi run'* ]]; then
                ensure_pixi_is_available
            fi
            if [ -z "$current_cmd" ]; then
                run_eval "$target_cmd"
            else
                run_eval "$target_cmd $force_flag"
            fi
            run jaq --arg installer "$installer" --arg pkg "$pkg" --arg cmd "$target_cmd" \
              '.[$installer][$pkg] = $cmd' --to yaml -ji "$current_file"
        fi
    done
}

sync "$1" "$2"
