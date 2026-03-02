#!/bin/bash

if niceterm; then
    prompt='󰍉 '
    pointer=' '
    marker='✓ '
else
    prompt='? '
    pointer='> '
    marker='+ '
fi

case "$OS_KERNEL" in
"Darwin")
    preview='fzf-preview.sh'
    ;;
"Linux")
    preview='/usr/share/fzf/fzf-preview.sh'
    ;;
esac

fzf_colors="bg:-1,bg+:-1,fg:white,fg+:yellow,border:gray,spinner:magenta,hl:yellow,header:blue,info:green,pointer:yellow,marker:green,prompt:blue,hl+:red"

export FZF_DEFAULT_OPTS="--style full
--layout reverse
--prompt '$prompt'
--pointer '$pointer'
--marker '$marker'
--gutter ' '
--color '$fzf_colors'
--preview '$preview {}'
--bind 'ctrl-e:become(nvim {+})'
--bind 'ctrl-o:become(bat {+})'
--bind 'ctrl-y:execute(echo {} | pbcopy && echo Copied path to clipboard: {})+become(exit 0)'
--bind 'ctrl-u:execute(cat {} | pbcopy && echo Copied contents to clipboard: {})+become(exit 0)'
--bind 'ctrl-/:change-preview-window(hidden|)'
--bind 'esc:become(exit 0)'"

export FZF_ALT_C_OPTS="
--preview 'eza -T {}'
--bind 'ctrl-/:change-preview-window(hidden|)'"

eval "$(fzf --bash)"
