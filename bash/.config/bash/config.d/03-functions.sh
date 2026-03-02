#!/bin/bash

# Functions

function mkcd() {
    mkdir -p "$1" && cd "$1"
}

function niceterm() {
    # Check if the terminal supports nice features
    local term_programs=(ghostty kitty iTerm.app vscode Apple_Terminal)
    local term_names=(xterm-ghostty xterm-kitty alacritty terminator konsole hyper wezterm xterm-256color)

    if [[ " ${term_programs[*]} " == *" $TERM_PROGRAM "* ]] || [[ " ${term_names[*]} " == *" $TERM "* ]]; then
        return 0
    else
        return 1
    fi
}

function lsip() {
    # Display your public and local IP addresses
    local trace_url="https://www.cloudflare.com/cdn-cgi/trace"
    case "$1" in
    local)
        case "$2" in
        v4 | 4)
            if [[ "$(uname)" == "Darwin" ]]; then
                ifconfig | grep inet | grep -v inet6 | awk '{ print $2 }'
            else
                ip a | grep inet | grep -v inet6 | awk '{ print $2 }' | cut -d/ -f1
            fi
            ;;
        v6 | 6)
            if [[ "$(uname)" == "Darwin" ]]; then
                ifconfig | grep inet6 | awk '{ print $2 }'
            else
                ip a | grep inet6 | awk '{ print $2 }' | cut -d/ -f1
            fi
            ;;
        all)
            lsip local v4
            lsip local v6
            ;;
        *)
            lsip local v4
            ;;
        esac
        ;;
    public)
        curl -s "$trace_url" | sed -n 's/^ip=\([^ ]*\)/\1/p'
        ;;
    *)
        echo "Usage: lsip [local|public] [v4,4|v6,6|all]"
        ;;
    esac
}

function notify() {
    # Send a desktop notification
    local message="$1"
    local title="$2"

    if [[ -z "$message" ]]; then
        echo "Usage: notify \"Your message here\" [title]"
        return 1
    fi

    if [[ -z "$title" ]]; then
        title="Notification 🔔"
    fi

    if [[ "$(uname)" == "Darwin" ]]; then
        # macOS notification
        osascript -e "display notification \"$message\" with title \"$title\" sound name \"Submarine\""
    elif [[ "$(uname)" == "Linux" ]]; then
        # Linux notification
        notify-send "$title" "$message"
    fi
}
