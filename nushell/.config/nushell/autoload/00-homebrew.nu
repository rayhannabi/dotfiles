# 01-homebrew.nu

if ($nu.os-info | get name) == "macos" {
    use std/util "path add"

    load-env {
        HOMEBREW_CELLAR: /opt/homebrew/Cellar
        HOMEBREW_REPOSITORY: /opt/homebrew
        HOMEBREW_PREFIX: /opt/homebrew
    }
    
    path add /opt/homebrew/bin
    path add /opt/homebrew/sbin

    $env.MANPATH = [
        "/opt/homebrew/share/man"
        ...($env.MANPATH? | default [])
    ]

    $env.INFOPATH = [
        "/opt/homebrew/share/info"
        ...($env.INFOPATH? | default [])
    ]
}
