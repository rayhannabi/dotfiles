#! /usr/bin/env zsh

# use osascript to send a notification on macOS
# usage: notify "Your message here"
notify() {
    local message="$1"
    local title="${2:-"⌘ Notification"}"
    if [[ -z "$message" ]]; then
        echo "Usage: notify \"Your message here\" [title]"
        return 1
    fi
    if [[ -z "$title" ]]; then
        title="⌘ Notification"
    fi
    # Use osascript to display the notification
    osascript -e "display notification \"$message\" with title \"$title\""
}