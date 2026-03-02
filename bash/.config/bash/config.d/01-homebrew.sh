#!/bin/bash

if [[ $OS_KERNEL == "Darwin" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi
