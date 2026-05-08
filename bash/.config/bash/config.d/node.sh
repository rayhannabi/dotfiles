#!/bin/bash

# FNM - Fast Node Manager

eval "$(fnm env --use-on-cd --shell bash)"

# bun

export BUN_BIN_DIR="$HOME/.cache/.bun/bin"

# check if bun bin dir is in path
# if not, add it to path
case ":$PATH:" in
*":$BUN_BIN_DIR:"*) ;;
*) export PATH="$BUN_BIN_DIR:$PATH" ;;
esac
