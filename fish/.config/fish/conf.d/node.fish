#!/usr/bin/env fish

# FNM - Fast Node Manager

fnm env --use-on-cd --shell fish | source

# pnpm

set -gx PNPM_HOME "$HOME/.local/share/pnpm"

# check if pnpm home is in path
# if not, add it to path
if not contains $PNPM_HOME $PATH
    set -gx PATH $PNPM_HOME $PATH
end
