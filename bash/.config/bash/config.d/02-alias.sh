#!/bin/bash

alias cd='z'
alias l='eza -alh --icons=always --color=auto --sort=type'
alias ll='eza'
alias tree='eza -T'
alias lg='lazygit'
alias v='nvim'
alias p='preview'

if [[ -x "$(command -v pbcopy)" ]]; then
    alias pbcopy='wl-copy'
fi

if [[ -x "$(command -v pbpaste)" ]]; then
    alias pbpaste='wl-paste'
fi
