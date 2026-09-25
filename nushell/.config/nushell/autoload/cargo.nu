# cargo.nu

use std/util "path add"

$env.RUSTUP_HOME = ($env.XDG_CONFIG_HOME | path join rustup)
$env.CARGO_HOME = ($env.XDG_CONFIG_HOME | path join cargo)

path add ($env.CARGO_HOME | path join bin)
