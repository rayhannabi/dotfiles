#!/bin/zsh
#
# Darwin Homebrew shellenv
#

if os_is_darwin; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
