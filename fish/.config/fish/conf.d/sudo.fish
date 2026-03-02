#!/usr/bin/env fish
#
# Sudo Prompt
#

if niceterm
    set -gx SUDO_PROMPT "🔒 [%u@%h] Password: "
else
    set -gx SUDO_PROMPT "[%u@%h] Password: "
end
