# setup fzf

export-env { 
    $env.FZF_INTEGRATION_PATH = (
         $env.XDG_DATA_HOME 
        | path join nushell/vendor/autoload/fzf-integration.nu
    )
}

export def "setup fzf" [] {
    let path = $env.FZF_INTEGRATION_PATH
    mkdir ($path | path dirname)
    ^fzf --nushell | save --force $path

    print $"fzf integration installed at ($path)."
    print "Restart nushell for changes to take effect."
}
