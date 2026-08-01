#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

source common.bash

main() {
    ensures_configs_are_the_same_than_in_hardlinks_dir
    ensures_hardlinks_dir_is_up_to_date
    ensure_git_aliases
}

ensures_configs_are_the_same_than_in_hardlinks_dir() {
    local file
    for file in .bashrc .gitconfig; do
        ensures_second_file_is_hard_link_to_first hardlinks/"$file" ~/"$file"
    done
    ensures_second_file_is_hard_link_to_first hardlinks/config.fish ~/.config/fish/config.fish
    ensures_second_file_is_hard_link_to_first hardlinks/Makefile ~/Documents/git/Makefile
    ensures_second_dir_has_hard_links_to_first hardlinks/yazi ~/.config/yazi
}

ensures_hardlinks_dir_is_up_to_date() {
    # Do the reverse of `ensures_configs_are_the_same_than_in_hardlinks_dir`.
    # This is useful, for example, when there are new files in `~/.config/yazi`.
    local file
    for file in .bashrc .gitconfig; do
        ensures_second_file_is_hard_link_to_first ~/"$file" hardlinks/"$file"
    done
    ensures_second_file_is_hard_link_to_first ~/.config/fish/config.fish hardlinks/config.fish
    ensures_second_file_is_hard_link_to_first ~/Documents/git/Makefile hardlinks/Makefile
    ensures_second_dir_has_hard_links_to_first ~/.config/yazi hardlinks/yazi
}

ensures_second_dir_has_hard_links_to_first() {
    # The first directory is not modified.
    local src="$1" dst="$2"
    find "$src" -type f -printf '%P\0' | while IFS= read -rd $'\0' filesubpath; do
        ensures_second_file_is_hard_link_to_first "$src/$filesubpath" "$dst/$filesubpath"
    done
}

ensures_second_file_is_hard_link_to_first() {
    # The first file is not modified.
    local src="$1" dst="$2"
    if [ ! -f "$src" ]; then
        >&2 echo "no file $src"
        exit 1
    fi
    if [ -L "$src" ]; then
        >&2 echo "$src is a symlink"
        exit 1
    fi
    if [ ! "$dst" -ef "$src" ]; then
        if [ -f "$dst" ]; then
            if [ -L "$dst" ]; then
                >&2 echo "$dst is a symlink"
                exit 1
            fi
            run rm -- "$dst"
        else
            local dstdir
            dstdir="$(dirname "$dst")"
            if [ ! -d "$dstdir" ]; then
                run mkdir -p -- "$dstdir"
            fi
        fi
        run ln -- "$src" "$dst"
    fi
}

ensure_git_aliases() {
    if [ ! -f ~/.gitalias ]; then
        install_apt_package_if_executable_is_missing wget
        ensure_apt_packages_are_installed ca-certificates
        run wget https://raw.githubusercontent.com/GitAlias/gitalias/main/gitalias.txt -O ~/.gitalias
    fi
}

main
