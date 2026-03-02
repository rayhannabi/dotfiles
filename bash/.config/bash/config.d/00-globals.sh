#!/bin/bash

# Localization

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Editors
export EDITOR=nvim
export VISUAL=nvim
export MANPAGER='nvim +Man!'

# Less
export LESS='-R --mouse'

# GPG
export GPG_TTY=$(tty)

# OS specific
export OS_KERNEL="$(uname -s)"
export OS_ARCH="$(uname -m)"

# Bat
export BAT_THEME=OneHalfDark

function _export_android_paths() {
    export ANDROID_HOME="$HOME/Android/Sdk"
    export PATH="$PATH:$ANDROID_HOME/platform-tools"
    export PATH="$PATH:$ANDROID_HOME/tools"
    export PATH="$PATH:$ANDROID_HOME/tools/bin"
    export PATH="$PATH:$ANDROID_HOME/emulator"
}

function _export_java_paths() {
    if [[ "$(uname)" == "Darwin" ]]; then
        export JAVA_HOME=$(/usr/libexec/java_home)
    else
        export JAVA_HOME=/usr/lib/jvm/default
    fi
    export PATH="$PATH:$JAVA_HOME/bin"
}

function _export_cargo_paths() {
    export RUSTUP_HOME="$XDG_CONFIG_HOME/rustup"
    export CARGO_HOME="$XDG_CONFIG_HOME/cargo"
    export PATH="$PATH:$CARGO_HOME/bin"
}

export PATH="$PATH:$HOME/.local/bin"

_export_android_paths
_export_java_paths
_export_cargo_paths
