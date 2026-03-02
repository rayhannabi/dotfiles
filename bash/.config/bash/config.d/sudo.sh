#!/bin/sh

if niceterm; then
    export SUDO_PROMPT="🔒 [%u@%h] Password: "
else
    export SUDO_PROMPT="[%u@%h] Password: "
fi
