# starship.nu

use ../modules/term.nu

let conf_default = ($env.XDG_CONFIG_HOME | path join starship/config.toml)
let conf_ascii = ($env.XDG_CONFIG_HOME | path join starship/config-ascii.toml)

$env.STARSHIP_CONFIG = if (term is-nice) {
    $conf_default
} else {
    $conf_ascii
}

use ../modules/setup/starship.nu *

if not ($env.STARSHIP_INTEGRATION_PATH | path exists) {
    setup starship
}
