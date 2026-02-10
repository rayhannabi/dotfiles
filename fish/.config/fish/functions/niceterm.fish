#!/usr/bin/env fish

function niceterm
    # Check if the terminal supports nice features
    set -l term_programs ghostty kitty iTerm.app vscode Apple_Terminal
    set -l term_names xterm-ghostty xterm-kitty alacritty terminator konsole hyper wezterm xterm-256color

    if contains $TERM_PROGRAM $term_programs || contains $TERM $term_names
        return 0
    else
        return 1
    end
end
