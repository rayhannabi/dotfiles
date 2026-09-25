$env.config.show_banner = false

$env.config = (
    $env.config 
    | upsert hooks.pre_prompt (
        ($env.config.hooks.pre_prompt? | default []) ++ [{|| print "" }]
    )
)

source alias.nu

use modules/setup *
use modules/lsip
use modules/term.nu

use std/util "path add"

path add ($env.HOME | path join .local/bin)
