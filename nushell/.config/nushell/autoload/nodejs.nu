# nodejs.nu

use std/util "path add"

## Bun paths
$env.BUN_BIN_DIR = ($env.XDG_CACHE_HOME | path join .bun/bin)
path add $env.BUN_BIN_DIR
