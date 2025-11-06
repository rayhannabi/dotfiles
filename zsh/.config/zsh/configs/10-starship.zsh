#!/bin/zsh
#
# Starship
#

CONF="$XDG_CONFIG_HOME/starship/config.toml"
CONF_ASCII="$XDG_CONFIG_HOME/starship/config-ascii.toml"
CONF_JETPACK="$XDG_CONFIG_HOME/starship/config-jetpack.toml"

if term_is_nice; then
  # check if $JETPACK is set to 1
  if [[ -n "$JETPACK" && "$JETPACK" -eq 1 ]]; then
    export STARSHIP_CONFIG=$CONF_JETPACK
  else
    export STARSHIP_CONFIG=$CONF
  fi
else
  export STARSHIP_CONFIG=$CONF_ASCII
fi

eval "$(starship init zsh)"
