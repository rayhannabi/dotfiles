#!/usr/bin/env fish

# Starship

set -l conf "$XDG_CONFIG_HOME/starship/config.toml"
set -l conf_ascii "$XDG_CONFIG_HOME/starship/config-ascii.toml"
set -l conf_jetpack "$XDG_CONFIG_HOME/starship/config-jetpack.toml"

if niceterm
    # check if $JETPACK is set to 1
    if test -n "$JETPACK" -a "$JETPACK" -eq 1
        set -gx STARSHIP_CONFIG $conf_jetpack
    else
        set -gx STARSHIP_CONFIG $conf
    end
else
    set -gx STARSHIP_CONFIG $conf_ascii
end

function starship_transient_prompt_func
    starship module character
end

starship init fish | source
enable_transience
