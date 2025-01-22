#!/bin/zsh
#
# Starship
#

conf="$XDG_CONFIG_HOME/starship/config.toml"
conf_plain="$XDG_CONFIG_HOME/starship/config-plaintext.toml"

if os_is_darwin; then
  export STARSHIP_CONFIG=conf_plain
else
  case $(tty) in
  /dev/tty[0-9]*) export STARSHIP_CONFIG=conf_plain ;;
  *) export STARSHIP_CONFIG=conf ;;
  esac
fi
eval "$(starship init zsh)"
