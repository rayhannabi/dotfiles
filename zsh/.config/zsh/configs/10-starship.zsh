#!/bin/zsh
#
# Starship
#

CONF="$XDG_CONFIG_HOME/starship/config.toml"
CONF_ASCII="$XDG_CONFIG_HOME/starship/config-ascii.toml"

if term_is_nice; then
  export STARSHIP_CONFIG=$CONF
else
  export STARSHIP_CONFIG=$CONF_ASCII
fi

eval "$(starship init zsh)"
