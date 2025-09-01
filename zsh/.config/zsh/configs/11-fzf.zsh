#!/bin/zsh
#
# FZF
#

FZF_COLORS="bg:-1,\
bg+:-1,\
fg:white,\
fg+:yellow,\
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

if term_is_nice; then
  export FZF_DEFAULT_OPTS="
  --style=full \
  --layout=reverse \
  --prompt='󰍉 '\
  --pointer=' ' \
  --marker='✓ ' \
	--color=$FZF_COLORS"
else
  export FZF_DEFAULT_OPTS="
  --style=full \
  --layout=reverse \
  --prompt='? '\
  --pointer='> ' \
  --marker='+ ' \
	--color=$FZF_COLORS"
fi

source <(fzf --zsh)

alias fzp="fzf --preview='fzf-preview.sh {}'"
