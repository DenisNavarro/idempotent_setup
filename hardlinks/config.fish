
set -g fish_greeting # Remove the fish greeting

if status is-interactive
    abbr -a -g b bash -c
    abbr -a -g c codium
    abbr -a -g ca cargo
    abbr -a -g cdd cd ~/Documents/
    abbr -a -g cdg cd ~/Documents/git/
    abbr -a -g cdi cd ~/Documents/git/idempotent_setup/
    abbr -a -g cdr cd ~/Documents/git/rust_pocs/
    abbr -a -g cdrb cd ~/Documents/git/rust_pocs/bin_from_ninja/
    abbr -a -g cdrc cd ~/Documents/git/rust_pocs/coroutine/
    abbr -a -g cdrs cd ~/Documents/git/rust_pocs/structured_concurrency/
    abbr -a -g cds cd ~/Documents/git/sync_install/
    abbr -a -g cdx 'cd -- "$(xclip -o -selection clipboard)"'
    abbr -a -g cg codium -g
    abbr -a -g co "perl -pe 'chomp if eof' | xclip -selection clipboard" # Copy
    abbr -a -g cwd "pwd | perl -pe 'chomp if eof' | xclip -selection clipboard" # Copy Working Directory
    abbr -a -g e eza
    abbr -a -g ef "$EDITOR" '"$(fzf)"'
    abbr -a -g ei "$EDITOR" ~/Documents/git/idempotent_setup/
    abbr -a -g er "$EDITOR" ~/Documents/git/rust_pocs/
    abbr -a -g es "$EDITOR" ~/Documents/git/sync_install/
    abbr -a -g f fish
    abbr -a -g fe fend
    abbr -a -g g git
    abbr -a -g j just
    abbr -a -g m make
    abbr -a -g n 'nautilus . &'
    abbr -a -g p pixi run
    abbr -a -g pa xclip -o -selection clipboard # Paste
    abbr -a -g po podman
    abbr -a -g r 'realpath $(fzf) | xclip -selection clipboard'
    abbr -a -g rg- rg --sort path -.
    abbr -a -g rgf rg --sort path -F.
    abbr -a -g rgfi rg --sort path -Fi.
    abbr -a -g rgfiw rg --sort path -Fiw.
    abbr -a -g rgfw rg --sort path -Fw.
    abbr -a -g rgi rg --sort path -i.
    abbr -a -g rgiw rg --sort path -iw.
    abbr -a -g rgn rg --no-heading --sort path -.
    abbr -a -g rgnf rg --no-heading --sort path -F.
    abbr -a -g rgnfi rg --no-heading --sort path -Fi.
    abbr -a -g rgnfiw rg --no-heading --sort path -Fiw.
    abbr -a -g rgnfw rg --no-heading --sort path -Fw.
    abbr -a -g rgni rg --no-heading --sort path -i.
    abbr -a -g rgniw rg --no-heading --sort path -iw.
    abbr -a -g rgnw rg --no-heading --sort path -w.
    abbr -a -g rgw rg --sort path -w.
    abbr -a -g t gio trash
    abbr -a -g te gio trash --empty
    abbr -a -g u cd ../ # Up
    abbr -a -g w gnome-terminal --tab -- fish
    abbr -a -g x 'xdg-open $(fzf)'
    abbr -a -g zce zed ~/Bureau/install/code/extended_bin_from_ninja/
    abbr -a -g zi zed ~/Documents/git/idempotent_setup/
    abbr -a -g zr zed ~/Documents/git/rust_pocs/
    abbr -a -g zrb zed ~/Documents/git/rust_pocs/bin_from_ninja/
    abbr -a -g zrc zed ~/Documents/git/rust_pocs/coroutine/
    abbr -a -g zrs zed ~/Documents/git/rust_pocs/structured_concurrency/
    abbr -a -g zs zed ~/Documents/git/sync_install/

    # See https://yazi-rs.github.io/docs/quick-start
    function y
        set tmp (mktemp -t 'yazi-cwd.XXXXXX')
        command yazi $argv --cwd-file="$tmp"
        if read -z cwd <"$tmp"; and [ "$cwd" != "$PWD" ]; and test -d "$cwd"
            builtin cd -- "$cwd"
        end
        command rm -f -- "$tmp"
    end
end

function mkcd --description 'Create a directory if it does not exist, then cd to it'
    if test (count $argv) -ne 1
        if test (count $argv) -eq 0
            echo 'There should be one argument. Usage: mkcd dir_path' >&2
        else
            echo 'There should be only one argument. Usage: mkcd dir_path' >&2
        end
        return 1
    end
    command mkdir -p -- $argv[1]
    and cd -- $argv[1]
end

function fish_prompt --description 'Write out the prompt'
    set -l last_pipestatus $pipestatus
    set -lx __fish_last_status $status # Export for __fish_print_pipestatus.
    set -l normal (set_color --reset)

    # Color the prompt differently when we're root
    set -l color_cwd $fish_color_cwd
    set -l suffix '>'
    if functions -q fish_is_root_user; and fish_is_root_user
        if set -q fish_color_cwd_root
            set color_cwd $fish_color_cwd_root
        end
        set suffix '#'
    end

    # Write pipestatus
    # If the status was carried over (if no command is issued or if `set` leaves the status untouched), don't bold it.
    set -l bold_flag --bold
    set -q __fish_prompt_status_generation; or set -g __fish_prompt_status_generation $status_generation
    if test $__fish_prompt_status_generation = $status_generation
        set bold_flag
    end
    set __fish_prompt_status_generation $status_generation
    set -l status_color (set_color $fish_color_status)
    set -l statusb_color (set_color $bold_flag $fish_color_status)
    set -l prompt_status (__fish_print_pipestatus "[" "]" "|" "$status_color" "$statusb_color" $last_pipestatus)

    # From the default definition in https://github.com/fish-shell/fish-shell/blob/4.8.1/share/functions/fish_prompt.fish
    # echo -n -s (prompt_login)' ' (set_color $color_cwd) (prompt_pwd) $normal (fish_vcs_prompt) $normal " "$prompt_status $suffix " "

    # Modified last line:
    echo -n -s (set_color $color_cwd) (prompt_pwd) $normal $prompt_status $suffix " "
end
