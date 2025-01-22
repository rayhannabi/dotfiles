#!/bin/zsh
#
# Directory helpers
#

alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ......="cd ../../../../.."

alias -- -="cd -"
alias 0="cd -0"
alias 1="cd -1"
alias 2="cd -2"
alias 3="cd -3"
alias 4="cd -4"
alias 5="cd -5"
alias 6="cd -6"
alias 9="cd -9"

alias md="mkdir -p"

mkcd() {
  local dir="$*"
  mkdir -p "$dir" && cd "$dir"
}

d() {
  if [[ -n "$1" ]]; then
    dirs = "$@"
  else
    dirs -v | head -n 10
  fi
}

# compdef _dirs d
