#!/usr/bin/env fish

# FZF

if niceterm
    set prompt '󰍉 '
    set pointer ' '
    set marker '✓ '
else
    set prompt '? '
    set pointer '> '
    set marker '+ '
end

switch (uname)
    case Darwin
        set preview 'fzf-preview.sh'
    case Linux
        set preview '/usr/share/fzf/fzf-preview.sh'
end

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

set -gx FZF_DEFAULT_OPTS "--style full
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

set -gx FZF_ALT_C_OPTS "
--preview 'eza -T {}'
--bind 'ctrl-/:change-preview-window(hidden|)'"

fzf --fish | source
