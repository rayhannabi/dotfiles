#!/bin/sh

# XDG Base Directories
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

# Iterate over all files in config.d and source them
for config_file in "$XDG_CONFIG_HOME/bash/config.d/"*.sh; do
    if [ -f "$config_file" ]; then
        . "$config_file"
    fi
done
