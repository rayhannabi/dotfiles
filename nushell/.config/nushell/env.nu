# Global environment variables
use std/util

# Localization

load-env {
    LANG: en_US.UTF-8
    LC_ALL: en_US.UTF-8
}

# XDG
load-env {
    XDG_CONFIG_HOME: ($env.HOME | path join .config)
    XDG_DATA_HOME: ($env.HOME | path join .local/share)
    XDG_STATE_HOME: ($env.HOME | path join .local/state)
    XDG_CACHE_HOME: ($env.HOME | path join .cache)
}

# Editors
load-env {
    EDITOR: nvim
    VISUAL: nvim
}

# Pagers
load-env {
    PAGER: less
    LESS: "-R --mouse"
    MANPAGER: "bat -p -l man"
}

# GPG
$env.GPG_TTY = (tty)

# Conversions

$env.ENV_CONVERSIONS = {
    MANPATH: {
        from_string: { |s| $s | split row (char esep) }
        to_string: { |v| $v | str join (char esep) }
    }
    INFOPATH: {
        from_string: { |s| $s | split row (char esep) }
        to_string: { |v| $v | str join (char esep) }
    }
}
