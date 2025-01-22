#!/bin/zsh

public-ip() {
  trace_url="https://cloudflare.com/cdn-cgi/trace"
  curl -s $trace_url | sed -n 's/^ip=\([^ ]*\)/\1/p'
}

private-ip() {
  ipv4() {
    if os_is_darwin; then
      ifconfig | grep inet | grep -v inet6 | awk '{ print $2 }'
    else
      ip a | grep inet | grep -v inet6 | awk '{ print $2 }' | cut -d/ -f1
    fi
  }

  ipv6() {
    if os_is_darwin; then
      ifconfig | grep inet6 | awk '{ print $2 }'
    else
      ip a | grep inet6 | awk '{ print $2 }' | cut -d/ -f1
    fi
  }

  case "${1:-4}" in
  4) ipv4 ;;
  6) ipv6 ;;
  *) echo -e "Invalid option $1.\nValid options:\n\t- '4' or <empty> for IPv4\n\t- '6' for IPv6" && false ;;
  esac
}
