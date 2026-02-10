#!/usr/bin/env fish

if test (uname) = Linux
    set -gx CHROME_EXECUTABLE google-chrome-stable
end
