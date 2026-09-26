# lsip module

export def main [] {
    print "Local IP address:"
    local | table -e | print

    print "Public IP address:"
    public | table -e | print
}

export def local [] {
    match ($nu.os-info | get name) {
        linux => (lsip linux)
        macos => (lsip macos)
    }
}

export def public [] {
    try { 
      http get "https://ident.me/json"
    } catch { 
        try {
            http get -e "https://www.cloudflare.com/cdn-cgi/trace"
            | lines
            | parse "{key}={value}"
            | into record
        } catch {
          { error: "offline or connection failed" }
        }
    }
}

def "lsip linux" [] {
    def scalar-or-list [] {
        if ($in | length) <= 1 {
            $in | get -o 0
        } else {
            $in
        }
    }

    ip -j addr
    | from json
    | each { |row|
        {
            interface: $row.ifname
            ipv4: ($row.addr_info | where family == 'inet' | get local | scalar-or-list)
            ipv6: ($row.addr_info | where family == 'inet6' | get local | scalar-or-list)
        }
    }
}

def "lsip macos" [] {
    ifconfig
    | parse -r '(?ms)^(?<interface>\S+):(?<body>.*?)(?=^\S+:|\z)'
    | each { |row|
        {
            interface: $row.interface
            ipv4: (
                $row.body
                | parse -r '(?m)^\s*inet\s+(?<address>\S+)'
                | get -o 0.address
            )
            ipv6: (
                $row.body
                | parse -r '(?m)^\s*inet6\s+(?<address>\S+)'
                | get -o 0.address
            )
        }
    }
    | where { ($in.ipv4 | is-not-empty) or ($in.ipv6 | is-not-empty) }
}
