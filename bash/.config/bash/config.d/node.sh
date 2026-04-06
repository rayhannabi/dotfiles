#!/bin/bash

# FNM - Fast Node Manager

eval "$(fnm env --use-on-cd --shell bash)"

# pnpm

export PNPM_HOME="$HOME/.local/share/pnpm"

# check if pnpm home is in path
# if not, add it to path
case ":$PATH:" in
*":$PNPM_HOME:"*) ;;
*) export PATH="$PNPM_HOME:$PATH" ;;
esac
