function fzp --wraps='fzf --preview="fzf-preview.sh {}"' --description 'alias fzp fzf --preview="fzf-preview.sh {}"'
    fzf --preview="fzf-preview.sh {}" $argv
end
