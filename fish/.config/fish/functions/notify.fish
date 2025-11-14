#!/usr/bin/env fish

# notify.fish

function notify -d "Send a desktop notification"
    set -l message $argv[1]
    set -l title $argv[2]

    if test -z "$message"
        echo "Usage: notify \"Your message here\" [title]"
        return 1
    end

    if test -z "$title"
        set title "Notification 🔔"
    end

    if test (uname) = Darwin
        # macOS notification
        osascript -e "display notification \"$message\" with title \"$title\" sound name \"Submarine\""
    else if test (uname) = Linux
        # Linux notification
        notify-send "$title" "$message"
    end
end
