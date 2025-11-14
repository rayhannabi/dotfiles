#!/usr/bin/env fish
# Darwin Homebrew shellenv

if test (uname) = Darwin
    /opt/homebrew/bin/brew shellenv | source
end
