#!/bin/env fish

# Localization
set -gx LANG en_US.UTF-8
set -gx LC_ALL en_US.UTF-8

# Editors
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx MANPAGER 'nvim +Man!'

# Less
set -gx LESS '-R --mouse'

# GPG
set -gx GPG_TTY (tty)

# Paths
# Android
set -gx ANDROID_HOME "$HOME/Android/Sdk"
set -gx PATH $PATH "$ANDROID_HOME/platform-tools"
set -gx PATH $PATH "$ANDROID_HOME/tools"
set -gx PATH $PATH "$ANDROID_HOME/tools/bin"
set -gx PATH $PATH "$ANDROID_HOME/emulator"
set -gx PATH $PATH "$ANDROID_HOME/cmdline-tools/latest/bin"

# Java
if test (uname) = Darwin
    set -gx JAVA_HOME ( /usr/libexec/java_home )
else
    set -gx JAVA_HOME /usr/lib/jvm/default
end
set -gx PATH $PATH "$JAVA_HOME/bin"

# Rust cargo
set -gx RUSTUP_HOME $XDG_CONFIG_HOME/rustup
set -gx CARGO_HOME $XDG_CONFIG_HOME/cargo
set -gx PATH $PATH "$CARGO_HOME/bin"

# bat
set -gx BAT_THEME OneHalfDark

function fish_greeting
end

function new_line --on-event fish_postexec
    echo ""
end

# Added by LM Studio CLI (lms)
set -gx PATH $PATH /Users/rayhan/.lmstudio/bin
# End of LM Studio CLI section
