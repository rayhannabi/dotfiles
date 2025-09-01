#!/bin/zsh

export OS_KERNEL=$(uname -s)

os_is_darwin() {
  [[ "$OS_KERNEL" == "Darwin" ]]
}

os_is_linux() {
  [[ "$OS_KERNEL" == "Linux" ]]
}

term_is_nice() {
  [[ "$TERM_PROGRAM" == "ghostty" ||
    "$TERM_PROGRAM" == "kitty" ||
    "$TERM_PROGRAM" == "iTerm.app" ||
    "$TERM_PROGRAM" == "vscode" ||
    "$TERM_PROGRAM" == "Apple_Terminal" ||
    "$TERM" == "xterm-kitty" ||
    "$TERM" == "alacritty" ||
    "$TERM" == "terminator" ||
    "$TERM" == "konsole" ||
    "$TERM" == "hyper" ||
    "$TERM" == "wezterm" ]]
}
