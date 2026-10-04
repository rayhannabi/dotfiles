# golang.nu

use std/util "path add"

$env.GOPATH = ($env.HOME | path join ".local/go")

path add ($env.GOPATH | path join "bin")
