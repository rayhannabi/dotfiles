#!/usr/bin/env fish

function mkcd --description 'Make a directory and change into it'
    mkdir -p $argv
    cd $argv
end
