$env.NU_LIB_DIRS ++= [
    ($nu.config-path | path dirname | path join "modules")
]

$env.config.show_banner = false

$env.config = (
    $env.config 
    | upsert hooks.pre_prompt (
        ($env.config.hooks.pre_prompt? | default []) ++ [{|| print "" }]
    )
)

source alias.nu

use std/util "path add"
use modules/setup *
use modules/utils *
use modules/lsip
use modules/term.nu

path add ($env.HOME | path join .local/bin)

# Theme
use themes/tokyo-night.nu
tokyo-night set color_config
