#!/usr/bin/env fish

function cd --description 'Change directory and list contents'
    # use zoxide to change directory if available
    if type -q zoxide
        z $argv
    else
        builtin cd $argv
    end
end
