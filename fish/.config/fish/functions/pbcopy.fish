function pbcopy -d 'Copy to clipboard'
    switch (uname)
        case Darwin
            command pbcopy $argv
        case Linux
            wl-copy $argv
    end
end
