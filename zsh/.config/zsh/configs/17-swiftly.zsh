#!/bin/zsh

#
# Swiftly
#

SWIFTLY_ENV="$HOME/.local/share/swiftly/env.sh"

if os_is_linux && [ -f $SWIFTLY_ENV ]; then
  . $SWIFTLY_ENV
fi
