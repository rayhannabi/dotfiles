# setup zoxide

export-env { 
    $env.ZOXIDE_INTEGRATION_PATH = (
         $env.XDG_DATA_HOME 
        | path join nushell/vendor/autoload/zoxide-integration.nu
    )
}

export def "setup zoxide" [] {
    let path = $env.ZOXIDE_INTEGRATION_PATH
    mkdir ($path | path dirname)
    ^zoxide init nushell | save --force $path

    print $"zoxide integration installed at ($path)."
    print "Restart nushell for changes to take effect."
}
