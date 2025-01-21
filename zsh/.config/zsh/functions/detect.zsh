#!/bin/zsh

export OS_KERNEL=$(uname -s)

os_is_darwin() {
  [[ "$OS_KERNEL" == "Darwin" ]]
}

os_is_linux() {
  [[ "$OS_KERNEL" == "Linux" ]]
}
