# rbenv.nu
use std/util "path add"

$env.RBENV_ROOT = ($env.RBENV_ROOT? | default $"($nu.home-dir)/.rbenv")

path add ($env.RBENV_ROOT | path join shims)

export def --env "rbenv use" [version: string] {
    $env.RBENV_VERSION = $version
}

export def --env "rbenv default" [] {
    hide-env RBENV_VERSION
}
