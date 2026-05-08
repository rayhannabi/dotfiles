#!/usr/bin/env fish
#
# Sudo Prompt
#

if niceterm
    set -gx SUDO_PROMPT "🔑 Password (%u@%h): "
else
    set -gx SUDO_PROMPT "# Password (%u@%h):"
end
