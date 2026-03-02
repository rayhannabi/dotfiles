#!/usr/bin/env fish

# Starship

set -l conf "$XDG_CONFIG_HOME/starship/config.toml"
set -l conf_ascii "$XDG_CONFIG_HOME/starship/config-ascii.toml"

if niceterm
    set -gx STARSHIP_CONFIG $conf
else
    set -gx STARSHIP_CONFIG $conf_ascii
end

starship init fish | source
