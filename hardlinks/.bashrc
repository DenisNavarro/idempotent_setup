#!/usr/bin/env bash

if [ -d ~/.pixi/bin ] && [[ ":$PATH:" != *":$HOME/.pixi/bin:"* ]]; then
    export PATH="$HOME/.pixi/bin:$PATH"
fi

for bindir in ~/.cargo/bin ~/bin ~/.local/bin ~/.elan/bin ~/.opam/default/bin; do
    if [ -d "$bindir" ] && [[ ":$PATH:" != *":$bindir:"* ]]; then
        export PATH="$PATH:$bindir"
    fi
done

if command -v fresh >/dev/null 2>&1; then
    export EDITOR=fresh
elif command -v nano >/dev/null 2>&1; then
    export EDITOR=nano
fi

echo -en "\e[8;38;180t" # Resize terminal

alias cdd='cd ~/Documents/'
alias cdg='cd ~/Documents/git/'
alias cdi='cd ~/Documents/git/idempotent_setup/'
alias cdr='cd ~/Documents/git/rust_pocs/'
alias cdrb='cd ~/Documents/git/rust_pocs/bin_from_ninja/'
alias cdrc='cd ~/Documents/git/rust_pocs/coroutine/'
alias cdrs='cd ~/Documents/git/rust_pocs/structured_concurrency/'
alias cds='cd ~/Documents/git/sync_install/'
alias cdx='cd -- "$(xclip -o -selection clipboard)"'
alias co="perl -pe 'chomp if eof' | xclip -selection clipboard"  # Copy
alias cw="pwd | perl -pe 'chomp if eof' | xclip -selection clipboard"
alias ef='"$EDITOR" "$(fzf)"'
alias ei='"$EDITOR" ~/Documents/git/idempotent_setup/'
alias er='"$EDITOR" ~/Documents/git/rust_pocs/'
alias es='"$EDITOR" ~/Documents/git/sync_install/'
alias f='exec fish'
alias g=git
alias m=make
alias pa='xclip -o -selection clipboard'  # Paste
alias r='realpath $(fzf) | xclip -selection clipboard'
alias u='cd ..'  # Up
alias w='gnome-terminal --tab -- fish'
alias x='xdg-open "$(fzf)"'
alias zi='zed ~/Documents/git/idempotent_setup/'
alias zr='zed ~/Documents/git/rust_pocs/'
alias zrb='zed ~/Documents/git/rust_pocs/bin_from_ninja/'
alias zrc='zed ~/Documents/git/rust_pocs/coroutine/'
alias zrs='zed ~/Documents/git/rust_pocs/structured_concurrency/'
alias zs='zed ~/Documents/git/sync_install/'

mkcd() {
    if [ $# -ne 1 ]; then
        if [ $# -eq 0 ]; then
            echo 'There should be one argument. Usage: mkcd dir_path' >&2
        else
            echo 'There should be only one argument. Usage: mkcd dir_path' >&2
        fi
        return 1
    fi
    if [ "$1" = - ]; then
        set -- -/
    fi
    # '|| return' is useless here but satisfies ShellCheck: https://www.shellcheck.net/wiki/SC2164
    mkdir -p -- "$1" && cd -- "$1" || return
}

# See https://yazi-rs.github.io/docs/quick-start
function y() {
    local tmp cwd
	tmp="$(mktemp -t 'yazi-cwd.XXXXXX')"
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd" || true
	command rm -f -- "$tmp"
}
