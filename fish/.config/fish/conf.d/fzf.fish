#!/usr/bin/env fish

# FZF

set -l fzf_colors "bg:-1,
bg+:-1,
fg:white,
fg+:yellow,
border:gray,
spinner:magenta,
hl:yellow,
header:blue,
info:green,
pointer:yellow,
marker:green,
prompt:blue,
hl+:red"

if niceterm
    set prompt '󰍉 '
    set pointer ' '
    set marker '✓ '
else
    set prompt '? '
    set pointer '> '
    set marker '+ '
end

set -gx FZF_DEFAULT_OPTS "--style=full
--layout=reverse
--prompt='$prompt'
--pointer='$pointer'
--marker='$marker'
--gutter=' '
--color='$fzf_colors'"

fzf --fish | source
