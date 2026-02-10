function fzp --wraps='fzf --preview="fzf-preview.sh {}"' --description 'alias fzp fzf --preview="fzf-preview.sh {}"'
    if test (uname) = Linux
        set preview '/usr/share/fzf/fzf-preview.sh {}'
    else
        set preview 'fzf-preview.sh {}'
    end
    fzf --preview=$preview $argv
end
