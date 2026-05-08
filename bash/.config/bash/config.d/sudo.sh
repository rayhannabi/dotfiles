#!/bin/sh

if niceterm; then
    export SUDO_PROMPT="🔑 Password (%u@%h): "
else
    export SUDO_PROMPT="# Password (%u@%h): "
fi
