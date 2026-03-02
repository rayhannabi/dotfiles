#!/bin/sh

# manual swiftly exports

export SWIFTLY_HOME_DIR="$HOME/.local/share/swiftly"
export SWIFTLY_BIN_DIR="$SWIFTLY_HOME_DIR/bin"
export SWIFTLY_TOOLCHAINS_DIR="$SWIFTLY_HOME_DIR/toolchains"

# preprend swiftly bin to PATH if not already present
if ! echo "$PATH" | grep -q "$SWIFTLY_BIN_DIR"; then
    export PATH="$SWIFTLY_BIN_DIR:$PATH"
fi
