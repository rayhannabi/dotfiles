#!/bin/zsh
#
# Global variables
#

## ZSH
export HISTFILE="$ZDOTDIR/.zsh_history"
export HISTSIZE=10000
export SAVEHIST=10000

# Localization
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Editors
export EDITOR=nvim
export VISUAL=nvim

# Less
export LESS='-R --mouse'

# GPG
export GPG_TTY=$(tty)

# Paths

## Android
export ANDROID_HOME="$HOME/Android/Sdk"
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin

## Java
if os_is_darwin; then
  export JAVA_HOME=$(/usr/libexec/java_home)
else
  export JAVA_HOME="/usr/lib/jvm/default"
fi
export PATH=$PATH:$JAVA_HOME/bin

## Rust cargo
export RUSTUP_HOME=$XDG_CONFIG_HOME/rustup
export CARGO_HOME=$XDG_CONFIG_HOME/cargo
export PATH=$PATH:$CARGO_HOME/bin

## bat
export BAT_THEME=OneHalfDark
