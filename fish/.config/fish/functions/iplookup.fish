#!/usr/bin/env fish

function iplookup -d "Display your public and local IP addresses"
    function ip_local
        switch $argv[1]
            case 4 v4
                ip_local4
            case 6 v6
                ip_local6
            case all
                ip_local4
                ip_local6
            case "*"
                ip_local4
        end
    end

    function ip_local4
        if test (uname) = Darwin
            ifconfig | grep inet | grep -v inet6 | awk '{ print $2 }'
        else
            ip a | grep inet | grep -v inet6 | awk '{ print $2 }' | cut -d/ -f1
        end
    end

    function ip_local6
        if test (uname) = Darwin
            ifconfig | grep inet6 | awk '{ print $2 }'
        else
            ip a | grep inet6 | awk '{ print $2 }' | cut -d/ -f1
        end
    end

    function ip_public
        set -l trace_url "https://www.cloudflare.com/cdn-cgi/trace"
        curl -s $trace_url | sed -n 's/^ip=\([^ ]*\)/\1/p'
    end

    switch $argv[1]
        case local
            ip_local $argv[2]
        case public
            ip_public
        case "*"
            if test (uname) = Darwin
                echo "Usage: ip [local|public] [v4,4|v6,6|all]"
            else
                command ip $argv
            end
    end
end
