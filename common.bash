#!/usr/bin/env bash
set -euo pipefail

RUST_VERSION=1.97.1
RUST_TOOLCHAINS=(1.97.1)
JAQ_VERSION=3.1.0

ensure_uv_is_available() {
    ensure_recipes_are_available
    ensure_mandatory_exe_is_installed_with uv pixi
}

ensure_recipes_are_available() {
    ensure_pixi_is_available
    if [[ ":$PATH:" != *":$HOME/.pixi/bin:"* ]]; then
        export PATH="$HOME/.pixi/bin:$PATH"
    fi
}

clean_pixi_cache() {
    ensure_pixi_is_available
    run pixi clean cache --yes
}

ensure_pixi_is_available() {
    ensure_mandatory_exe_is_installed_with pixi cargo
}

ensure_mandatory_exe_is_installed_with() {
    local exename="$1" installer="$2"
    # `jaq` is almost a superset of `jq` and works with various formats, including YAML.
    ensure_jaq_is_available
    if ! command -v "$exename" >/dev/null 2>&1; then
        local cmd
        # Get the command to execute from `target_state.yaml`.
        cmd="$(jaq -r --arg installer "$installer" --arg pkg "$exename" '.[$installer][$pkg]' target_state.yaml)"
        run_eval "$cmd"
        # Save the executed command in `current_state.yaml`.
        # Otherwise, later, `sync.bash current_state.yaml target_state.yaml` would execute it again.
        run jaq --arg installer "$installer" --arg pkg "$exename" --arg cmd "$cmd" \
          '.[$installer][$pkg] = $cmd' --to yaml -ji current_state.yaml
    fi
}

# `jaq` is almost a superset of `jq` and works with various formats, including YAML.
ensure_jaq_is_available() {
    ensure_cargo_is_available
    if ! command -v jaq >/dev/null 2>&1; then
        install_apt_package_if_executable_is_missing gcc
        ensure_apt_packages_are_installed libc6-dev
        local cmd='cargo +'"$RUST_VERSION"' install jaq --version '"$JAQ_VERSION"' --locked'
        run_eval "$cmd"
        ensure_current_yaml_is_initialized current_state.yaml
        # Save the executed command in `current_state.yaml`.
        # Otherwise, later, `sync.bash current_state.yaml target_state.yaml` would execute it again.
        run jaq --arg crate jaq --arg cmd "$cmd" \
          '.cargo[$crate] = $cmd' --to yaml -ji current_state.yaml
    fi
}

ensure_current_yaml_is_initialized() {
    local file="$1"
    if [ ! -f "$file" ]; then
        run_eval 'echo '\''{"cargo": {}, "pixi": {}, "uv": {}}'\'' > '"$file"
    fi
}

ensure_cargo_is_available() {
    if ! command -v cargo >/dev/null 2>&1; then
        _ensure_rust_is_installed
        if [[ ":$PATH:" != *":$HOME/.cargo/bin:"* ]]; then
            export PATH="$PATH:$HOME/.cargo/bin"
        fi
    fi
    local toolchain
    for toolchain in "${RUST_TOOLCHAINS[@]}"; do
        _ensure_has_rust_toolchain "$toolchain"
    done
    _ensure_default_rust_toolchain "$RUST_VERSION"
}

_ensure_rust_is_installed() {
    if [ ! -f ~/.cargo/bin/cargo ]; then
        install_apt_package_if_executable_is_missing wget
        ensure_apt_packages_are_installed ca-certificates
        # See https://github.com/rust-lang/docker-rust/blob/master/stable/bookworm/slim/Dockerfile
        run wget https://static.rust-lang.org/rustup/archive/1.29.0/x86_64-unknown-linux-gnu/rustup-init
        run chmod +x rustup-init
        run ./rustup-init -y --no-modify-path --default-toolchain "$RUST_VERSION"
        run rm rustup-init
    fi
}

_ensure_default_rust_toolchain() {
    local toolchain="$1"
    _ensure_has_rust_toolchain "$toolchain"
    if [[ "$(rustup show active-toolchain)" != "$toolchain"-* ]]; then
        run rustup default "$toolchain"
    fi
}

_ensure_has_rust_toolchain() {
    local toolchain="$1"
    if ! _has_rust_toolchain "$toolchain"; then
        run rustup toolchain install "$toolchain"
    fi
}

_has_rust_toolchain() {
    local toolchain="$1"
    local line
    while IFS= read -r line; do
        [[ "$line" == "$toolchain"-* ]] && return 0
    done < <(rustup toolchain list)
    return 1
}

# Similar to `cargo cache -r all` without installing `cargo-cache`
clean_cargo_cache() {
    local subpath
    for subpath in git/db git/checkouts registry/src registry/cache registry/index; do
        if [ -e "$HOME/.cargo/$subpath" ]; then
            run rm -rf -- "$HOME/.cargo/$subpath"
        fi
    done
}

install_apt_package_for_each_missing_executable() {
    local pkg
    for pkg in "$@"; do
        install_apt_package_if_executable_is_missing "$pkg"
    done
}

install_apt_package_if_executable_is_missing() {
    local pkg="$1" exename="${2:-$1}"
    if ! command -v "$exename" >/dev/null 2>&1; then
        run sudo apt-get update
        run sudo apt-get install -y --no-install-recommends "$pkg"
    fi
}

ensure_apt_packages_are_installed() {
    local packages_to_install=()
    local pkg
    for pkg in "$@"; do
        local status rc=0
        status="$(dpkg-query -Wf='${db:Status-Status}' "$pkg")" || rc=$?
        if [ "$rc" -ne 0 ] || [ "$status" != installed ]; then
            packages_to_install+=("$pkg")
        fi
    done
    if [ ${#packages_to_install[@]} -ne 0 ]; then
        run sudo apt-get update
        run sudo apt-get install -y --no-install-recommends "${packages_to_install[@]}"
    fi
}

# Not used in the published `idempotent_setup` but useful to share
install_apt_package_if_gcc_cannot_include() {
    local pkg="$1"
    if ! echo "#include <$2>" | gcc -E -x c - > /dev/null 2>&1; then
        run sudo apt-get update
        run sudo apt-get install -y --no-install-recommends "$pkg"
    fi
}

# Not used in the published `idempotent_setup` but useful to share with Ubuntu users
install_snap_package_if_executable_is_missing() {
    local pkg="$1" exename="${2:-$1}"
    if ! command -v "$exename" >/dev/null 2>&1; then
        run sudo snap install "$pkg"
    fi
}

# Not used in the published `idempotent_setup` but useful to share with Ubuntu users
install_classic_snap_package_if_executable_is_missing() {
    local pkg="$1" exename="${2:-$1}"
    if ! command -v "$exename" >/dev/null 2>&1; then
        run sudo snap install --classic "$pkg"
    fi
}

# `run` and `run_eval` write to stdout, then execute a command.
# `verify_setup.bash`, in a Podman image, executes several scripts twice and check each time that
# the second call to the script prints nothing to stdout and stderr.
# So it checks that the second call to the script does not call `run` or `run_eval`.
# Most commands mut be called with `run` or `run_eval`, except "request" commands.
# This is how `verify_setup.bash` verifies idempotency.

run_eval() {
    echo "+ $1"
    eval "$1"
}

run() {
    printf '+ ' && _print_shell_command "$@"
    "$@"
}

_print_shell_command() {
    local result=()
    local arg
    for arg in "$@"; do
        result+=("$(printf %q "$arg")")
    done
    echo "${result[*]}"
}
