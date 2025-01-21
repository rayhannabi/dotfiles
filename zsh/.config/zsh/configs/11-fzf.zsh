#!/bin/zsh
#
# FZF
#

FZF_COLORS="bg:-1,\
bg+:-1,\
fg:gray,\
fg+:bright-white,\
border:gray,\
spinner:magenta,\
hl:yellow,\
header:blue,\
info:green,\
pointer:yellow,\
marker:green,\
prompt:blue,\
hl+:red,\
gutter:-1"

export FZF_DEFAULT_OPTS="
  --style=full \
  --layout=reverse \
  --prompt='󰍉 '\
  --pointer=' ' \
  --marker=' ' \
	--color=$FZF_COLORS"

source <(fzf --zsh)

alias fzfp="fzf --preview='fzf-preview.sh {}'"
