#!/bin/zsh
#
# Alias definitions

alias zshrc="eval '$EDITOR $ZDOTDIR/.zshrc'"
alias zshenv="eval '$EDITOR $HOME/.zshenv'"
alias zshcomp-rebuild="rm $ZDOTDIR/.zcompdump; compinit; bashcompinit"

alias ls=eza
alias l="ls -alh --icons=always --colour=auto --sort=type"
alias lg=lazygit
