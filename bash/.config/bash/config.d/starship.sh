#!/bin/sh

starship_conf="$XDG_CONFIG_HOME/starship/config.toml"
starship_conf_ascii="$XDG_CONFIG_HOME/starship/config-ascii.toml"

if niceterm; then
    export STARSHIP_CONFIG="$starship_conf"
else
    export STARSHIP_CONFIG="$starship_conf_ascii"
fi

eval "$(starship init bash)"
