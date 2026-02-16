function pbpaste -d 'Paste from clipboard'
    switch (uname)
        case Darwin
            command pbpaste $argv
        case Linux
            wl-paste $argv
    end
end
