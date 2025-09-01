#!/bin/zsh
#
# Starship
#

CONF="$XDG_CONFIG_HOME/starship/config.toml"
CONF_ASCII="$XDG_CONFIG_HOME/starship/config-ascii.toml"

if os_is_darwin; then
  export STARSHIP_CONFIG=$CONF
fi

if os_is_linux; then
  case $(tty) in
  /dev/tty[0-9]*)
    export STARSHIP_CONFIG=$CONF_ASCII
    ;;
  *)
    export STARSHIP_CONFIG=$CONF_ASCII
    ;;
  esac
fi

eval "$(starship init zsh)"
