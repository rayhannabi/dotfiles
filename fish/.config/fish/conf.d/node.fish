#!/usr/bin/env fish

# FNM - Fast Node Manager

fnm env --use-on-cd --shell fish | source

# bun

set -gx BUN_BIN_DIR "$HOME/.cache/.bun/bin"

# check if bun bin dir is in path
# if not, add it to path
if not contains $BUN_BIN_DIR $PATH
    set -gx PATH $BUN_BIN_DIR $PATH
end
