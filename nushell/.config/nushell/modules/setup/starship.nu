# setup starship

export-env { 
    $env.STARSHIP_INTEGRATION_PATH = (
         $env.XDG_DATA_HOME 
        | path join nushell/vendor/autoload/starship-integration.nu
    )
}

export def "setup starship" [] {
    let path = $env.STARSHIP_INTEGRATION_PATH
    mkdir ($path | path dirname)
    ^starship init nu | save --force $path

    print $"starship integration installed at ($path)."
    print "Restart nushell for changes to take effect."
}
